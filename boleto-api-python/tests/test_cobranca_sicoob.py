import pytest

from app.providers.sicoob import SicoobProvider, SICOOB_SCOPES, _map_status
from app.schemas import Status


@pytest.fixture
def sicoob_env(monkeypatch):
    monkeypatch.setenv("VAULT__imob1__sicoob__client_id", "cid")
    monkeypatch.setenv("VAULT__imob1__sicoob__client_secret", "sec")
    # cobrança registrada do Sicoob pronta (senão cai no fallback brcobrança)
    monkeypatch.setenv("SICOOB_REGISTERED_READY", "true")


def test_sicoob_status_mapping():
    assert _map_status("REGISTRADO") == Status.registrado
    assert _map_status("LIQUIDADO") == Status.liquidado
    assert _map_status("BAIXADO") == Status.baixado


def test_sicoob_client_usa_scopes_e_header_client_id():
    p = SicoobProvider(account_config={}, credentials={"client_id": "cid", "client_secret": "s"})
    c = p._client()
    assert c.scopes == SICOOB_SCOPES
    assert c.default_headers.get("client_id") == "cid"


def test_sicoob_registrar_mapeia_identificadores_e_normaliza(client, cobranca_payload, sicoob_env, monkeypatch):
    captured = {}

    def fake_request(self, method, path, json=None):
        captured.update(method=method, path=path, json=json)
        return {
            "resultado": {
                "nossoNumero": "77",
                "situacao": "REGISTRADO",
                "linhaDigitavel": "75691.23456",
                "pixCopiaECola": "0002...",
            }
        }

    monkeypatch.setattr("app.clients.oauth_mtls.OAuthMtlsClient.request", fake_request)

    body = {
        "tenant_id": "imob1",
        "provider": "sicoob",
        "account_config": {"numeroCliente": 99, "codigoModalidade": 1, "cooperativa": "0001"},
        "cobranca": cobranca_payload,
    }
    r = client.post("/cobranca", json=body)
    assert r.status_code == 200, r.text
    data = r.json()
    assert data["id"] == "77"
    assert data["status"] == "registrado"
    assert data["linha_digitavel"].startswith("75691")

    # identificadores do account_config foram para o payload do Sicoob
    assert captured["json"]["numeroCliente"] == 99
    assert captured["json"]["codigoModalidade"] == 1
    assert captured["json"]["nossoNumero"] == "123"
    assert captured["json"]["seuNumero"] == "A-1"
