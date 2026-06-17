# Schemas canônicos (pydantic v2) — contrato estável que o Gestão-Contrato consome.
#
# O mesmo shape serve qualquer provider (C6, Sicoob, brcobrança offline). Cada
# provider traduz para o seu banco; a resposta volta normalizada.
from __future__ import annotations

from decimal import Decimal
from datetime import date, datetime
from enum import Enum
from typing import Any

from pydantic import BaseModel, Field


class Provider(str, Enum):
    brcobranca = "brcobranca"  # offline/CNAB (motor Ruby)
    c6 = "c6"
    sicoob = "sicoob"


class Status(str, Enum):
    registrado = "registrado"
    pendente = "pendente"
    liquidado = "liquidado"
    baixado = "baixado"
    erro = "erro"


class Pagador(BaseModel):
    nome: str
    documento: str  # CPF/CNPJ
    endereco: dict[str, Any] | None = None


class Cobranca(BaseModel):
    valor: Decimal
    vencimento: date
    nosso_numero: str | None = None
    seu_numero: str | None = None
    pagador: Pagador
    multa: dict[str, Any] | None = None
    juros: dict[str, Any] | None = None
    desconto: dict[str, Any] | None = None


class CobrancaIn(BaseModel):
    tenant_id: str
    provider: Provider
    # blob por provider; cada Provider lê o seu (não unificado de propósito):
    #   c6:     { agencia, conta, convenio }
    #   sicoob: { cooperativa, conta, numeroCliente, codigoModalidade }
    account_config: dict[str, Any] = Field(default_factory=dict)
    cobranca: Cobranca


class CobrancaOut(BaseModel):
    id: str | None = None
    status: Status
    linha_digitavel: str | None = None
    codigo_barras: str | None = None
    pix_copia_cola: str | None = None
    pdf_base64: str | None = None
    raw: dict[str, Any] | None = None


class WebhookEvent(BaseModel):
    event: str
    id: str | None = None
    status: Status | None = None
    paid_at: datetime | None = None
    valor: Decimal | None = None
    raw: dict[str, Any] | None = None
