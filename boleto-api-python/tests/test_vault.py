import pytest

from app.core.vault import EnvVault


def test_env_vault_reads_credentials(monkeypatch):
    monkeypatch.setenv("VAULT__imob1__c6__client_id", "cid")
    monkeypatch.setenv("VAULT__imob1__c6__client_secret", "sec")
    monkeypatch.setenv("VAULT__imob1__c6__pfx_password", "pw")

    creds = EnvVault().get_credentials("imob1", "c6")
    assert creds == {"client_id": "cid", "client_secret": "sec", "pfx_password": "pw"}


def test_env_vault_isolates_tenants(monkeypatch):
    monkeypatch.setenv("VAULT__imob1__c6__client_id", "cid1")
    monkeypatch.setenv("VAULT__imob2__c6__client_id", "cid2")
    assert EnvVault().get_credentials("imob2", "c6") == {"client_id": "cid2"}


def test_env_vault_missing_raises(monkeypatch):
    with pytest.raises(KeyError):
        EnvVault().get_credentials("inexistente", "c6")
