# Schemas canônicos (pydantic v2) — contrato estável que os consumidores usam.
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
    """Provider de cobrança. `brcobranca` = offline/CNAB (engine Ruby)."""

    brcobranca = "brcobranca"
    c6 = "c6"
    sicoob = "sicoob"


class Status(str, Enum):
    """Status normalizado da cobrança (igual para qualquer banco)."""

    registrado = "registrado"
    pendente = "pendente"
    liquidado = "liquidado"
    baixado = "baixado"
    erro = "erro"


class Pagador(BaseModel):
    nome: str = Field(description="Nome do pagador", examples=["Fulano de Tal"])
    documento: str = Field(description="CPF ou CNPJ (só dígitos)", examples=["12345678901"])
    endereco: dict[str, Any] | None = Field(default=None, description="Endereço do pagador (opcional)")


class Cobranca(BaseModel):
    valor: Decimal = Field(description="Valor da cobrança", examples=["1000.00"])
    vencimento: date = Field(description="Data de vencimento (ISO)", examples=["2026-07-10"])
    nosso_numero: str | None = Field(default=None, description="Nosso número (opcional; o banco pode atribuir)")
    seu_numero: str | None = Field(default=None, description="Seu número / identificador do emissor (opcional)")
    pagador: Pagador
    multa: dict[str, Any] | None = Field(default=None, description="Regras de multa (opcional)")
    juros: dict[str, Any] | None = Field(default=None, description="Regras de juros (opcional)")
    desconto: dict[str, Any] | None = Field(default=None, description="Regras de desconto (opcional)")


class CobrancaIn(BaseModel):
    tenant_id: str = Field(description="Identificador do tenant (resolve credenciais no cofre)", examples=["imob_123"])
    provider: Provider
    account_config: dict[str, Any] = Field(
        default_factory=dict,
        description=(
            "Blob por provider (não unificado de propósito). "
            "c6: {agencia, conta, convenio}; "
            "sicoob: {cooperativa, conta, numeroCliente, codigoModalidade}."
        ),
    )
    cobranca: Cobranca


class CobrancaOut(BaseModel):
    """Resposta normalizada — mesmo shape para qualquer provider."""

    id: str | None = Field(default=None, description="Id da cobrança no banco (nosso número/txid)")
    status: Status
    linha_digitavel: str | None = None
    codigo_barras: str | None = None
    pix_copia_cola: str | None = Field(default=None, description="PIX copia-e-cola (EMV), quando híbrido")
    pdf_base64: str | None = Field(default=None, description="PDF do boleto em base64, quando disponível")
    raw: dict[str, Any] | None = Field(default=None, description="Resposta crua do banco (debug)")


class WebhookEvent(BaseModel):
    """Evento normalizado de pagamento — também o corpo do push aos consumidores."""

    event: str = Field(description="Tipo do evento", examples=["cobranca.atualizada", "pix.recebido"])
    id: str | None = Field(default=None, description="Id da cobrança / txid")
    status: Status | None = None
    paid_at: datetime | None = Field(default=None, description="Data/hora do pagamento, se liquidado")
    valor: Decimal | None = Field(default=None, description="Valor pago, se aplicável")
    raw: dict[str, Any] | None = None


class CarneIn(BaseModel):
    tenant_id: str = Field(description="Identificador do tenant", examples=["imob_123"])
    provider: Provider
    account_config: dict[str, Any] = Field(default_factory=dict, description="Blob por provider (ver CobrancaIn)")
    bank: str = Field(description="Nome brcobrança para renderizar o carnê", examples=["banco_c6"])
    parcelas: list[Cobranca] = Field(description="Parcelas do carnê (registradas individualmente)")


class CarneOut(BaseModel):
    carne_pdf_base64: str | None = Field(default=None, description="PDF do carnê 3-vias em base64")
    cobrancas: list[CobrancaOut] = Field(default_factory=list, description="Cobranças registradas (uma por parcela)")
