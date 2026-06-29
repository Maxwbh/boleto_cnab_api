# Cliente do engine BrCobrança (Ruby) — chamadas de renderização.
#
# Usado pelo caminho offline/CNAB e pela montagem de carnê. Sem segredo.
from __future__ import annotations

import os
from typing import Any

import httpx


def engine_url() -> str:
    return os.environ.get("BOLETO_ENGINE_URL", "http://boleto-engine:9292").rstrip("/")


def render_boleto(bank: str, data: dict[str, Any]) -> dict[str, Any]:
    return _post("/api/render/boleto", {"bank": bank, "data": data})


def render_carne(bank: str, boletos: list[dict[str, Any]]) -> dict[str, Any]:
    # Carnê 3-vias A4 (template 'carne' no engine, sem GhostScript).
    return _post("/api/render/carne", {"bank": bank, "boletos": boletos})


def _post(path: str, payload: dict[str, Any]) -> dict[str, Any]:
    with httpx.Client(timeout=30.0) as c:
        r = c.post(f"{engine_url()}{path}", json=payload)
        r.raise_for_status()
        return r.json() if r.content else {}
