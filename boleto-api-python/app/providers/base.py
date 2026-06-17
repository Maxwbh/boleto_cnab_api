# Interface comum a todos os providers (porte do BaseProvider Ruby).
from __future__ import annotations

from abc import ABC, abstractmethod
from typing import Any

from app.schemas import Cobranca, CobrancaOut, WebhookEvent


class BankProvider(ABC):
    def __init__(self, *, account_config: dict[str, Any], credentials: dict[str, Any]) -> None:
        self.account_config = account_config
        self.credentials = credentials  # do cofre; em memória, não persiste

    @abstractmethod
    def registrar(self, cobranca: Cobranca) -> CobrancaOut: ...

    @abstractmethod
    def consultar(self, cobranca_id: str) -> CobrancaOut: ...

    @abstractmethod
    def baixar(self, cobranca_id: str) -> CobrancaOut: ...

    def normalizar_webhook(self, headers: dict[str, str], body: dict[str, Any]) -> WebhookEvent:
        raise NotImplementedError
