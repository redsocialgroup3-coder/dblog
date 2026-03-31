def test_list_regulations_returns_list(client, seed_regulations):
    """GET /regulations/ retorna una lista."""
    response = client.get("/regulations/")
    assert response.status_code == 200

    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 1


def test_list_regulations_filter_by_municipality(client, seed_regulations):
    """GET /regulations/?municipality=Madrid retorna solo Madrid."""
    response = client.get("/regulations/", params={"municipality": "Madrid"})
    assert response.status_code == 200

    data = response.json()
    assert len(data) == 1
    assert data[0]["municipality"] == "Madrid"


def test_list_municipalities(client, seed_regulations):
    """GET /regulations/municipalities retorna lista de municipios."""
    response = client.get("/regulations/municipalities")
    assert response.status_code == 200

    data = response.json()
    assert isinstance(data, list)
    assert "Madrid" in data
    assert "España (Ley 37/2003)" in data


def test_lookup_returns_specific_regulation(client, seed_regulations):
    """GET /regulations/lookup retorna regulacion especifica."""
    response = client.get(
        "/regulations/lookup",
        params={
            "municipality": "Madrid",
            "zone_type": "residencial",
            "time_period": "diurno",
            "noise_type": "exterior",
        },
    )
    assert response.status_code == 200

    data = response.json()
    assert data["municipality"] == "Madrid"
    assert data["db_limit"] == 60.0


def test_lookup_fallback_to_ley_37(client, seed_regulations):
    """GET /regulations/lookup con municipio desconocido retorna fallback Ley 37/2003."""
    response = client.get(
        "/regulations/lookup",
        params={
            "municipality": "Pueblo Desconocido",
            "zone_type": "residencial",
            "time_period": "diurno",
            "noise_type": "exterior",
        },
    )
    assert response.status_code == 200

    data = response.json()
    assert data["municipality"] == "España (Ley 37/2003)"
    assert data["db_limit"] == 65.0


def test_lookup_returns_404_for_invalid_combination(client, seed_regulations):
    """GET /regulations/lookup retorna 404 si no hay regulacion ni fallback."""
    response = client.get(
        "/regulations/lookup",
        params={
            "municipality": "Pueblo Desconocido",
            "zone_type": "parque_tematico",
            "time_period": "diurno",
            "noise_type": "exterior",
        },
    )
    assert response.status_code == 404


def test_verdict_supera(client, seed_regulations):
    """GET /regulations/verdict retorna SUPERA cuando medicion excede limite."""
    response = client.get(
        "/regulations/verdict",
        params={
            "municipality": "Madrid",
            "zone_type": "residencial",
            "time_period": "diurno",
            "noise_type": "exterior",
            "measured_db": 70.0,
        },
    )
    assert response.status_code == 200

    data = response.json()
    assert data["verdict"] == "SUPERA"
    assert data["limit_db"] == 60.0
    assert data["measured_db"] == 70.0


def test_verdict_no_supera(client, seed_regulations):
    """GET /regulations/verdict retorna NO_SUPERA cuando medicion es baja."""
    response = client.get(
        "/regulations/verdict",
        params={
            "municipality": "Madrid",
            "zone_type": "residencial",
            "time_period": "diurno",
            "noise_type": "exterior",
            "measured_db": 45.0,
        },
    )
    assert response.status_code == 200

    data = response.json()
    assert data["verdict"] == "NO_SUPERA"
