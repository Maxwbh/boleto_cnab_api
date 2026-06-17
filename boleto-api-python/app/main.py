from __future__ import annotations

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

from app.core.vault import CredentialNotFound
from app.routers import cobranca, webhooks

app = FastAPI(
    title="Boleto-API (Python)",
    version="0.1.0",
    description="Gateway de cobrança multi-banco (C6/Sicoob) + proxy ao motor brcobrança (Ruby).",
)

app.include_router(cobranca.router)
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
