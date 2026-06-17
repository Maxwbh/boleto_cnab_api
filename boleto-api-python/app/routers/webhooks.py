from __future__ import annotations

from fastapi import APIRouter, Request

from app.providers.c6 import C6Provider
from app.providers.sicoob import SicoobProvider
from app.schemas import WebhookEvent

router = APIRouter(prefix="/webhooks", tags=["webhooks"])

_NORMALIZERS = {"c6": C6Provider, "sicoob": SicoobProvider}


@router.post("/{banco}", response_model=WebhookEvent)
async def receber(banco: str, request: Request) -> WebhookEvent:
    body = await request.json()
    # TODO: validar autenticidade (assinatura/header) ANTES de confiar.
    klass = _NORMALIZERS.get(banco)
    if not klass:
        return WebhookEvent(event="ignorado", raw={"banco": banco})
    normalizer = klass(account_config={}, credentials={})
    event = normalizer.normalizar_webhook(dict(request.headers), body)
    # TODO: encaminhar `event` ao Gestão-Contrato (POST p/ URL em ENV, com retry).
    return event
