from __future__ import annotations

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

from app.core.vault import CredentialNotFound
from app.routers import carne, cobranca, webhooks

app = FastAPI(
    title="Boleto-API (Python)",
    version="0.1.0",
    description=(
        "Gateway de cobrança multi-banco (C6/Sicoob) + proxy ao engine brcobrança (Ruby).\n\n"
        "**Produto standalone** consumido por múltiplos sistemas; escopo por `tenant_id`.\n\n"
        "**Push de eventos (saída, não é um path desta API):** ao receber o webhook do "
        "banco, o gateway envia o evento normalizado (`WebhookEvent`) por `POST` ao "
        "consumidor dono do tenant, assinado em `X-Signature: sha256=<hmac_sha256(secret, "
        "raw_body)>`. Destino por tenant via `SUB__<tenant>__URL/SECRET`, com fallback "
        "global `EVENT_WEBHOOK_URL/SECRET`."
    ),
)

app.include_router(cobranca.router)
app.include_router(carne.router)
app.include_router(webhooks.router)


@app.exception_handler(CredentialNotFound)
async def _credential_not_found(request: Request, exc: CredentialNotFound) -> JSONResponse:
    # Tenant/provider não provisionado no cofre — erro de configuração, não 500.
    return JSONResponse(
        status_code=424,
        content={"detail": "credenciais do tenant/provider ausentes no cofre"},
    )


@app.get("/health", tags=["health"])
def health() -> dict[str, str]:
    return {"status": "ok"}
