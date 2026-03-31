from unittest.mock import patch


MOCK_FIREBASE_DATA = {
    "uid": "test-firebase-uid-123",
    "email": "test@dblog.app",
    "name": "Test User",
    "picture": None,
    "email_verified": True,
}


def test_verify_token_creates_user(client):
    """POST /auth/verify con token valido crea usuario y retorna datos."""
    with patch(
        "app.routers.auth.firebase_service.verify_token",
        return_value=MOCK_FIREBASE_DATA,
    ):
        response = client.post(
            "/auth/verify",
            json={"token": "fake-valid-firebase-token"},
        )

    assert response.status_code == 200

    data = response.json()
    assert data["firebase_uid"] == MOCK_FIREBASE_DATA["uid"]
    assert data["email"] == MOCK_FIREBASE_DATA["email"]
    assert data["display_name"] == MOCK_FIREBASE_DATA["name"]
    assert data["is_subscriber"] is False


def test_verify_token_returns_existing_user(client):
    """POST /auth/verify retorna usuario existente si ya fue creado."""
    with patch(
        "app.routers.auth.firebase_service.verify_token",
        return_value=MOCK_FIREBASE_DATA,
    ):
        # Primer llamado: crea el usuario.
        response1 = client.post(
            "/auth/verify",
            json={"token": "fake-valid-firebase-token"},
        )
        # Segundo llamado: retorna el mismo usuario.
        response2 = client.post(
            "/auth/verify",
            json={"token": "fake-valid-firebase-token"},
        )

    assert response1.status_code == 200
    assert response2.status_code == 200

    data1 = response1.json()
    data2 = response2.json()
    assert data1["id"] == data2["id"]


def test_verify_invalid_token_returns_401(client):
    """POST /auth/verify con token invalido retorna 401."""
    with patch(
        "app.routers.auth.firebase_service.verify_token",
        side_effect=Exception("Token inválido"),
    ):
        response = client.post(
            "/auth/verify",
            json={"token": "invalid-token"},
        )

    assert response.status_code == 401
    assert "inválido" in response.json()["detail"].lower() or "expirado" in response.json()["detail"].lower()


def test_get_me_without_auth_returns_403(client):
    """GET /auth/me sin token retorna 403."""
    response = client.get("/auth/me")
    assert response.status_code == 403


def test_get_me_with_invalid_token_returns_401(client):
    """GET /auth/me con token invalido retorna 401."""
    with patch(
        "app.dependencies.firebase_service.verify_token",
        side_effect=Exception("Token inválido"),
    ):
        response = client.get(
            "/auth/me",
            headers={"Authorization": "Bearer invalid-token"},
        )

    assert response.status_code == 401
