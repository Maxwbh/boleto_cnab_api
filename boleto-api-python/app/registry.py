# Roteador de providers + resolução de credenciais no cofre.
from __future__ import annotations

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


def build_provider(
    *, provider: Provider, tenant_id: str, account_config: dict[str, Any], vault: Vault
) -> BankProvider:
    klass = _PROVIDERS[provider]
    # offline (brcobrança) não precisa de credencial de banco
    credentials: dict[str, Any] = {}
    if provider is not Provider.brcobranca:
        credentials = vault.get_credentials(tenant_id, provider.value)
    return klass(account_config=account_config, credentials=credentials)
