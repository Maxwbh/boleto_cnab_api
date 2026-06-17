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
