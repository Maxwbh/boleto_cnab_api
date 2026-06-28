# Provider Sicoob (756) — Cobrança Bancária + PIX via API REST (mTLS + OAuth + scopes).
#
# Diferenças vs C6 que o cliente genérico absorve:
#   - OAuth com SCOPES obrigatórios
#   - header `client_id` em TODA request
#   - conciliação de boleto por POLLING (liquidação diária), não webhook
# Doc oficial é notoriamente incompleta -> fechar na sandbox por tentativa/erro.
from __future__ import annotations

import os
from typing import Any

from app.clients.oauth_mtls import OAuthMtlsClient
from app.providers.base import BankProvider
from app.schemas import Cobranca, CobrancaOut, Status, WebhookEvent

SICOOB_BASE = os.environ.get("SICOOB_BASE_URL", "https://api.sicoob.com.br")
SICOOB_AUTH = os.environ.get("SICOOB_AUTH_URL", "https://auth.sicoob.com.br/auth/realms/cooperado/protocol/openid-connect/token")  # TODO confirmar
SICOOB_SCOPES = ["cobranca_boletos_incluir", "cobranca_boletos_consultar", "cobranca_boletos_baixar"]


class SicoobProvider(BankProvider):
    def _client(self) -> OAuthMtlsClient:
        return OAuthMtlsClient(
            base_url=SICOOB_BASE,
            auth_url=SICOOB_AUTH,
            client_id=self.credentials["client_id"],
            client_secret=self.credentials.get("client_secret", ""),
            pfx_base64=self.credentials.get("pfx_base64", ""),
            pfx_password=self.credentials.get("pfx_password", ""),
            scopes=self.credentials.get("scopes", SICOOB_SCOPES),
            default_headers={"client_id": self.credentials["client_id"]},  # Sicoob exige
        )

    def registrar(self, cobranca: Cobranca) -> CobrancaOut:
        payload = {  # TODO mapear contrato real do Sicoob
            "numeroCliente": self.account_config.get("numeroCliente"),
            "codigoModalidade": self.account_config.get("codigoModalidade"),
            "valor": float(cobranca.valor),
            "dataVencimento": cobranca.vencimento.isoformat(),
            "nossoNumero": cobranca.nosso_numero,
            "seuNumero": cobranca.seu_numero,
            "pagador": {"nome": cobranca.pagador.nome, "numeroCpfCnpj": cobranca.pagador.documento},
        }
        data = self._client().request("POST", "/cobranca-bancaria/v3/boletos", json=payload)  # TODO path
        res = (data.get("resultado") or data)
        return CobrancaOut(
            id=str(res.get("nossoNumero") or res.get("seuNumero")),
            status=_map_status(res.get("situacao")) or Status.registrado,
            linha_digitavel=res.get("linhaDigitavel"),
            codigo_barras=res.get("codigoBarras"),
            pix_copia_cola=res.get("pixCopiaECola"),
            raw=data,
        )

    def consultar(self, cobranca_id: str) -> CobrancaOut:
        # Também é o que o WORKER de conciliação chama no polling agendado.
        data = self._client().request("GET", f"/cobranca-bancaria/v3/boletos/{cobranca_id}")  # TODO path
        res = (data.get("resultado") or data)
        return CobrancaOut(id=cobranca_id, status=_map_status(res.get("situacao")) or Status.pendente, raw=data)

    def baixar(self, cobranca_id: str) -> CobrancaOut:
        data = self._client().request("POST", f"/cobranca-bancaria/v3/boletos/{cobranca_id}/baixar")  # TODO path
        return CobrancaOut(id=cobranca_id, status=Status.baixado, raw=data)

    def normalizar_webhook(self, headers: dict[str, str], body: dict[str, Any]) -> WebhookEvent:
        # Sicoob: webhook é principalmente de PIX (array). Boleto vem por polling.
        return WebhookEvent(event="pix.recebido", id=body.get("txid"), status=Status.liquidado, raw=body)


def _map_status(s: str | None) -> Status | None:
    return {
        "REGISTRADO": Status.registrado, "EM_ABERTO": Status.registrado,
        "LIQUIDADO": Status.liquidado, "PAGO": Status.liquidado,
        "BAIXADO": Status.baixado,
    }.get((s or "").upper())
