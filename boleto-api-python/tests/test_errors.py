def test_cobranca_sem_credencial_retorna_424_nao_500(client, cobranca_payload):
    body = {
        "tenant_id": "nao-provisionado",
        "provider": "sicoob",
        "account_config": {},
        "cobranca": cobranca_payload,
    }
    r = client.post("/cobranca", json=body)
    assert r.status_code == 424
    assert "cofre" in r.json()["detail"]


def test_cobranca_payload_invalido_retorna_422(client):
    # falta pagador/valor -> validação do pydantic
    r = client.post("/cobranca", json={"tenant_id": "x", "provider": "c6", "cobranca": {}})
    assert r.status_code == 422
