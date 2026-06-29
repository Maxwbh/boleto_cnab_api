# Roteador de providers + resolução de credenciais no cofre.
from __future__ import annotations

import os
from typing import Any

from app.core.vault import Vault
from app.providers.base import BankProvider
from app.providers.brcobranca_proxy import BrcobrancaProxyProvider
from app.providers.c6 import C6Provider
from app.providers.sicoob import SicoobProvider
from app.schemas import Provider

_PROVIDERS: dict[Provider, type[BankProvider]] = {
    Provider.brcobranca: BrcobrancaProxyProvider,
    Provider.c6: C6Provider,
    Provider.sicoob: SicoobProvider,
}

# Nome do banco no brcobrança para o fallback offline (método antigo).
_BRCOBRANCA_BANK: dict[Provider, str] = {
    Provider.c6: "banco_c6",
    Provider.sicoob: "sicoob",
}


def registered_ready(provider: Provider) -> bool:
    """Indica se a cobrança REGISTRADA (API do banco) está homologada e pronta.

    Enquanto C6/Sicoob não estão 100%, o padrão é `False` → cai no método antigo
    (brcobrança offline). Liga por banco com `C6_REGISTERED_READY=true` /
    `SICOOB_REGISTERED_READY=true` após a homologação.
    """
    if provider is Provider.brcobranca:
        return True
    return os.environ.get(f"{provider.value.upper()}_REGISTERED_READY", "").lower() in ("1", "true", "yes")


def build_provider(
    *, provider: Provider, tenant_id: str, account_config: dict[str, Any], vault: Vault
) -> BankProvider:
    # Fallback: C6/Sicoob ainda não 100% → trata pelo método antigo (brcobrança
    # offline), sem precisar de credencial de banco.
    if provider in _BRCOBRANCA_BANK and not registered_ready(provider):
        cfg = {**account_config, "bank": account_config.get("bank") or _BRCOBRANCA_BANK[provider]}
        return BrcobrancaProxyProvider(account_config=cfg, credentials={})

    klass = _PROVIDERS[provider]
    # offline (brcobrança) não precisa de credencial de banco
    credentials: dict[str, Any] = {}
    if provider is not Provider.brcobranca:
        credentials = vault.get_credentials(tenant_id, provider.value)
    return klass(account_config=account_config, credentials=credentials)
