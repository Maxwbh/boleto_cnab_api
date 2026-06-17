from __future__ import annotations

from fastapi import FastAPI

from app.routers import cobranca, webhooks

app = FastAPI(
    title="Boleto-API (Python)",
    version="0.1.0",
    description="Gateway de cobrança multi-banco (C6/Sicoob) + proxy ao motor brcobrança (Ruby).",
)

app.include_router(cobranca.router)
app.include_router(webhooks.router)


@app.get("/health", tags=["health"])
def health() -> dict[str, str]:
    return {"status": "ok"}
