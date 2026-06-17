from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException

from app.core.vault import Vault, get_vault
from app.registry import build_provider
from app.schemas import CobrancaIn, CobrancaOut, Provider

router = APIRouter(prefix="/cobranca", tags=["cobranca"])


@router.post("", response_model=CobrancaOut)
def registrar(body: CobrancaIn, vault: Vault = Depends(get_vault)) -> CobrancaOut:
    provider = build_provider(
        provider=body.provider, tenant_id=body.tenant_id,
        account_config=body.account_config, vault=vault,
    )
    return provider.registrar(body.cobranca)


@router.get("/{cobranca_id}", response_model=CobrancaOut)
def consultar(
    cobranca_id: str, tenant_id: str, provider: Provider,
    vault: Vault = Depends(get_vault),
) -> CobrancaOut:
    p = build_provider(provider=provider, tenant_id=tenant_id, account_config={}, vault=vault)
    return p.consultar(cobranca_id)


@router.delete("/{cobranca_id}", response_model=CobrancaOut)
def baixar(
    cobranca_id: str, tenant_id: str, provider: Provider,
    vault: Vault = Depends(get_vault),
) -> CobrancaOut:
    p = build_provider(provider=provider, tenant_id=tenant_id, account_config={}, vault=vault)
    return p.baixar(cobranca_id)
