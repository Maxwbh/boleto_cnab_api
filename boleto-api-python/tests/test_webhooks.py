def test_webhook_c6_normaliza(client):
    r = client.post("/webhooks/c6", json={"id": "C6-1", "status": "PAID"})
    assert r.status_code == 200
    data = r.json()
    assert data["event"] == "cobranca.atualizada"
    assert data["id"] == "C6-1"
    assert data["status"] == "liquidado"


def test_webhook_sicoob_normaliza_pix(client):
    r = client.post("/webhooks/sicoob", json={"txid": "abc123", "valor": "50.00"})
    assert r.status_code == 200
    data = r.json()
    assert data["event"] == "pix.recebido"
    assert data["id"] == "abc123"
    assert data["status"] == "liquidado"


def test_webhook_banco_desconhecido_ignora(client):
    r = client.post("/webhooks/itau", json={"x": 1})
    assert r.status_code == 200
    assert r.json()["event"] == "ignorado"


def test_webhook_c6_faz_push_do_evento(client, monkeypatch):
    capturado = {}

    def fake_forward(event, *, url=None, secret=None):
        capturado.update(event)
        return True

    monkeypatch.setattr("app.routers.webhooks.forward_event", fake_forward)

    r = client.post("/webhooks/c6", json={"id": "C6-7", "status": "PAID"})
    assert r.status_code == 200
    # o evento normalizado foi encaminhado ao consumidor
    assert capturado["id"] == "C6-7"
    assert capturado["status"] == "liquidado"


def test_webhook_por_tenant_roteia_para_o_consumidor_dono(client, monkeypatch):
    monkeypatch.setenv("SUB__imobA__URL", "https://sistema-1.test/hook")
    monkeypatch.setenv("SUB__imobA__SECRET", "segA")
    destino = {}

    def fake_forward(event, *, url=None, secret=None):
        destino["url"] = url
        destino["secret"] = secret
        return True

    monkeypatch.setattr("app.routers.webhooks.forward_event", fake_forward)

    r = client.post("/webhooks/c6/imobA", json={"id": "C6-9", "status": "PAID"})
    assert r.status_code == 200
    assert destino == {"url": "https://sistema-1.test/hook", "secret": "segA"}
