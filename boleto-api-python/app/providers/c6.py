# Provider C6 (336) — boleto/PIX registrado via API REST (mTLS + OAuth).
#
# Auth: mTLS (PFX) + OAuth client_credentials. C6 não usa scopes nem header extra.
# Paths/payloads marcados com TODO p/ fechar na homologação (developers.c6bank.com.br).
from __future__ import annotations

import os
from typing import Any

from app.clients.oauth_mtls import OAuthMtlsClient
from app.providers.base import BankProvider
from app.schemas import Cobranca, CobrancaOut, Status, WebhookEvent

C6_BASE = os.environ.get("C6_BASE_URL", "https://baas-api-sandbox.c6bank.com.br")
C6_AUTH = os.environ.get("C6_AUTH_URL", f"{C6_BASE}/oauth/token")  # TODO confirmar


class C6Provider(BankProvider):
    def _client(self) -> OAuthMtlsClient:
        return OAuthMtlsClient(
            base_url=C6_BASE,
            auth_url=C6_AUTH,
            client_id=self.credentials["client_id"],
            client_secret=self.credentials["client_secret"],
            pfx_base64=self.credentials.get("pfx_base64", ""),
            pfx_password=self.credentials.get("pfx_password", ""),
        )

    def registrar(self, cobranca: Cobranca) -> CobrancaOut:
        payload = {  # TODO mapear contrato real do C6
            "amount": float(cobranca.valor),
            "dueDate": cobranca.vencimento.isoformat(),
            "ourNumber": cobranca.nosso_numero,
            "payer": {"name": cobranca.pagador.nome, "document": cobranca.pagador.documento},
        }
        data = self._client().request("POST", "/v1/bank-slips", json=payload)  # TODO path
        return CobrancaOut(
            id=data.get("id") or data.get("nossoNumero"),
            status=_map_status(data.get("status")) or Status.registrado,
            linha_digitavel=data.get("digitableLine"),
            codigo_barras=data.get("barcode"),
            pix_copia_cola=(data.get("pix") or {}).get("emv"),
            raw=data,
        )

    def consultar(self, cobranca_id: str) -> CobrancaOut:
        data = self._client().request("GET", f"/v1/bank-slips/{cobranca_id}")  # TODO path
        return CobrancaOut(id=cobranca_id, status=_map_status(data.get("status")) or Status.pendente, raw=data)

    def baixar(self, cobranca_id: str) -> CobrancaOut:
        data = self._client().request("DELETE", f"/v1/bank-slips/{cobranca_id}")  # TODO path
        return CobrancaOut(id=cobranca_id, status=Status.baixado, raw=data)

    def normalizar_webhook(self, headers: dict[str, str], body: dict[str, Any]) -> WebhookEvent:
        # TODO validar assinatura do webhook do C6
        return WebhookEvent(
            event="cobranca.atualizada",
            id=body.get("id") or body.get("nossoNumero"),
            status=_map_status(body.get("status")),
            raw=body,
        )


def _map_status(s: str | None) -> Status | None:
    return {
        "REGISTERED": Status.registrado, "ACTIVE": Status.registrado,
        "PAID": Status.liquidado, "SETTLED": Status.liquidado,
        "CANCELLED": Status.baixado, "WRITTEN_OFF": Status.baixado,
    }.get((s or "").upper())
