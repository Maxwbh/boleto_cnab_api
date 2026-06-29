from app.core.subscriptions import resolve_callback


def test_callback_por_tenant(monkeypatch):
    monkeypatch.setenv("SUB__imobA__URL", "https://a.test/hook")
    monkeypatch.setenv("SUB__imobA__SECRET", "segA")
    assert resolve_callback("imobA") == ("https://a.test/hook", "segA")


def test_fallback_global_quando_tenant_sem_callback(monkeypatch):
    monkeypatch.delenv("SUB__imobX__URL", raising=False)
    monkeypatch.setenv("EVENT_WEBHOOK_URL", "https://global.test/hook")
    monkeypatch.setenv("EVENT_WEBHOOK_SECRET", "segG")
    assert resolve_callback("imobX") == ("https://global.test/hook", "segG")


def test_none_sem_destino(monkeypatch):
    monkeypatch.delenv("EVENT_WEBHOOK_URL", raising=False)
    assert resolve_callback("qualquer") is None
    assert resolve_callback(None) is None


def test_tenants_distintos_roteiam_para_consumidores_distintos(monkeypatch):
    monkeypatch.setenv("SUB__imobA__URL", "https://sistema-1.test/hook")
    monkeypatch.setenv("SUB__imobB__URL", "https://sistema-2.test/hook")
    assert resolve_callback("imobA")[0] == "https://sistema-1.test/hook"
    assert resolve_callback("imobB")[0] == "https://sistema-2.test/hook"
