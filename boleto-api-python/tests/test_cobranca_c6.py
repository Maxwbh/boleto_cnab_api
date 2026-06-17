import pytest

from app.providers.c6 import C6Provider, _map_status
from app.schemas import Status


@pytest.fixture
def c6_env(monkeypatch):
    monkeypatch.setenv("VAULT__imob1__c6__client_id", "cid")
    monkeypatch.setenv("VAULT__imob1__c6__client_secret", "sec")
    # sem pfx -> contexto SSL default, não precisa de cert real no teste


def test_c6_status_mapping():
    assert _map_status("REGISTERED") == Status.registrado
    assert _map_status("PAID") == Status.liquidado
    assert _map_status("WRITTEN_OFF") == Status.baixado
    assert _map_status("???") is None


def test_c6_registrar_mapeia_payload_e_normaliza(client, cobranca_payload, c6_env, monkeypatch):
    captured = {}

    def fake_request(self, method, path, json=None):
        captured.update(method=method, path=path, json=json)
        return {
            "id": "C6-1",
            "status": "REGISTERED",
            "digitableLine": "00190.00009 12345",
            "barcode": "00190123",
            "pix": {"emv": "000201..."},
        }

    monkeypatch.setattr("app.clients.oauth_mtls.OAuthMtlsClient.request", fake_request)

    body = {
        "tenant_id": "imob1",
        "provider": "c6",
        "account_config": {"agencia": "0001", "conta": "123"},
        "cobranca": cobranca_payload,
    }
    r = client.post("/cobranca", json=body)
    assert r.status_code == 200, r.text
    data = r.json()
    assert data["id"] == "C6-1"
    assert data["status"] == "registrado"
    assert data["linha_digitavel"].startswith("00190")
    assert data["pix_copia_cola"] == "000201..."

    # payload mapeado para o contrato do C6
    assert captured["method"] == "POST"
    assert captured["json"]["amount"] == 1000.0
    assert captured["json"]["dueDate"] == "2026-07-10"
    assert captured["json"]["ourNumber"] == "123"


def test_c6_consultar_e_baixar(c6_env, monkeypatch):
    monkeypatch.setattr(
        "app.clients.oauth_mtls.OAuthMtlsClient.request",
        lambda self, method, path, json=None: {"status": "PAID"} if method == "GET" else {"status": "WRITTEN_OFF"},
    )
    p = C6Provider(account_config={}, credentials={"client_id": "c", "client_secret": "s"})
    assert p.consultar("X").status == Status.liquidado
    assert p.baixar("X").status == Status.baixado
