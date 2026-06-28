from __future__ import annotations

from fastapi import APIRouter, Request

from app.core.forwarder import forward_event
from app.core.subscriptions import resolve_callback
from app.providers.c6 import C6Provider
from app.providers.sicoob import SicoobProvider
from app.schemas import WebhookEvent

router = APIRouter(prefix="/webhooks", tags=["webhooks"])

_NORMALIZERS = {"c6": C6Provider, "sicoob": SicoobProvider}


async def _handle(banco: str, request: Request, tenant_id: str | None) -> WebhookEvent:
    body = await request.json()
    # TODO: validar autenticidade do webhook do BANCO (assinatura) antes de confiar.
    klass = _NORMALIZERS.get(banco)
    if not klass:
        return WebhookEvent(event="ignorado", raw={"banco": banco})

    event = klass(account_config={}, credentials={}).normalizar_webhook(dict(request.headers), body)

    # Push assinado (HMAC) ao consumidor DONO do tenant (multi-sistema). Sem
    # tenant na rota, cai no destino global. forward_event no-op se não houver destino.
    cb = resolve_callback(tenant_id)
    forward_event(event.model_dump(), url=cb[0] if cb else None, secret=cb[1] if cb else None)
    return event


@router.post("/{banco}", response_model=WebhookEvent)
async def receber(banco: str, request: Request) -> WebhookEvent:
    """Webhook global (consumidor único / destino default)."""
    return await _handle(banco, request, tenant_id=None)


@router.post("/{banco}/{tenant_id}", response_model=WebhookEvent)
async def receber_por_tenant(banco: str, tenant_id: str, request: Request) -> WebhookEvent:
    """Webhook por tenant (multi-sistema). O banco aponta o callback de cada conta
    para esta URL; o tenant vem do path e roteia para o consumidor dono."""
    return await _handle(banco, request, tenant_id=tenant_id)
