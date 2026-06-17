# Push de eventos normalizados para o Gestão-Contrato (Django).
#
# Quando o Boleto-API recebe um webhook do banco, normaliza e ENCAMINHA o evento
# para o Gestão-Contrato via POST assinado (HMAC-SHA256), para o Django validar
# de forma timing-safe (hmac.compare_digest).
#
# Esquema de assinatura (o Django deve validar igual):
#   header  X-Signature: sha256=<hex(hmac_sha256(secret, raw_body))>
#   body    JSON compacto (separators sem espaço), UTF-8
from __future__ import annotations

import hashlib
import hmac
import json
import os
from typing import Any

import httpx


def sign(body: bytes, secret: str) -> str:
    return "sha256=" + hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()


def forward_event(event: dict[str, Any]) -> bool:
    """Encaminha o evento ao Gestão-Contrato. Retorna True se entregue (2xx/3xx).

    No-op (False) se GESTAO_CONTRATO_WEBHOOK_URL não estiver configurado — o
    webhook do banco não deve falhar por causa do encaminhamento.
    """
    url = os.environ.get("GESTAO_CONTRATO_WEBHOOK_URL", "")
    if not url:
        return False

    secret = os.environ.get("BOLETO_API_WEBHOOK_SECRET", "")
    body = json.dumps(event, default=str, separators=(",", ":")).encode("utf-8")
    headers = {"Content-Type": "application/json"}
    if secret:
        headers["X-Signature"] = sign(body, secret)

    try:
        with httpx.Client(timeout=10.0) as c:
            r = c.post(url, content=body, headers=headers)
            return r.status_code < 400
    except httpx.HTTPError:
        # TODO: enfileirar para retry (o webhook do banco não pode quebrar aqui).
        return False
