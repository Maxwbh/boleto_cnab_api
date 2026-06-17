# Provider OFFLINE: faz proxy para o motor Ruby (brcobrança) via HTTP.
#
# É assim que o Python "troca de tecnologia" SEM jogar fora o brcobrança: o
# caminho offline/CNAB/carnê continua sendo renderizado pelo Boleto-Engine Ruby
# (o boleto_cnab_api atual, expondo /render/*). Sem segredo aqui.
from __future__ import annotations

import os
from typing import Any

import httpx

from app.providers.base import BankProvider
from app.schemas import Cobranca, CobrancaOut, Status

ENGINE_URL = os.environ.get("BOLETO_ENGINE_URL", "http://boleto-engine:9292")


class BrcobrancaProxyProvider(BankProvider):
    def registrar(self, cobranca: Cobranca) -> CobrancaOut:
        bank = self.account_config.get("bank")
        payload = {"bank": bank, "data": _to_engine_payload(cobranca, self.account_config)}
        with httpx.Client(timeout=30.0) as c:
            r = c.post(f"{ENGINE_URL}/api/render/boleto", json=payload)
            if r.status_code >= 400:
                return CobrancaOut(status=Status.erro, raw={"engine_status": r.status_code, "body": r.text})
            data = r.json()
        return CobrancaOut(
            id=data.get("nosso_numero"),
            status=Status.registrado,
            linha_digitavel=data.get("linha_digitavel"),
            codigo_barras=data.get("codigo_barras"),
            pdf_base64=data.get("pdf_base64"),
            raw=data,
        )

    # Offline não tem consulta/baixa online (conciliação via retorno/OFX no engine).
    def consultar(self, cobranca_id: str) -> CobrancaOut:
        return CobrancaOut(id=cobranca_id, status=Status.pendente,
                           raw={"hint": "offline: conciliar via retorno/OFX"})

    def baixar(self, cobranca_id: str) -> CobrancaOut:
        return CobrancaOut(id=cobranca_id, status=Status.baixado,
                           raw={"hint": "offline: baixa via remessa CNAB"})


def _to_engine_payload(cobranca: Cobranca, account_config: dict[str, Any]) -> dict[str, Any]:
    # TODO: mapear campos canônicos -> formato esperado pelo brcobrança no engine.
    return {
        "valor": float(cobranca.valor),
        "data_vencimento": cobranca.vencimento.isoformat(),
        "nosso_numero": cobranca.nosso_numero,
        "sacado": cobranca.pagador.nome,
        "sacado_documento": cobranca.pagador.documento,
        **account_config,
    }
