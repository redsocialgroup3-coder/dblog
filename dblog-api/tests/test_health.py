def test_health_returns_200(client):
    """GET /health retorna 200 y status ok."""
    response = client.get("/health")
    assert response.status_code == 200

    data = response.json()
    assert data["status"] == "ok"


def test_health_response_format(client):
    """GET /health retorna JSON con la estructura esperada."""
    response = client.get("/health")
    data = response.json()

    assert "status" in data
    assert isinstance(data["status"], str)
