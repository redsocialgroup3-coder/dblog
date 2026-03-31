"""
Datos de normativa de ruido para las 15 ciudades principales de España
y la Ley 37/2003 como fallback nacional.

Valores basados en las ordenanzas municipales reales de cada ciudad.
"""

from __future__ import annotations

from typing import Optional

REGULATIONS: list[dict] = []

# ---------------------------------------------------------------------------
# Helper para generar registros de una ciudad
# ---------------------------------------------------------------------------


def _add_city(
    municipality: str,
    regulation_name: str,
    article: Optional[str],
    limits: dict[tuple[str, str, str], float],
):
    """
    limits: {(zone_type, time_period, noise_type): db_limit}
    """
    for (zone_type, time_period, noise_type), db_limit in limits.items():
        REGULATIONS.append(
            {
                "municipality": municipality,
                "zone_type": zone_type,
                "time_period": time_period,
                "noise_type": noise_type,
                "db_limit": db_limit,
                "regulation_name": regulation_name,
                "article": article,
            }
        )


# ---------------------------------------------------------------------------
# Ley 37/2003 - Fallback nacional
# ---------------------------------------------------------------------------
_add_city(
    municipality="España (Ley 37/2003)",
    regulation_name="Ley 37/2003, del Ruido",
    article="Anexo II",
    limits={
        # Residencial
        ("residencial", "diurno", "interior"): 35.0,
        ("residencial", "diurno", "exterior"): 65.0,
        ("residencial", "nocturno", "interior"): 30.0,
        ("residencial", "nocturno", "exterior"): 55.0,
        ("residencial", "evening", "interior"): 33.0,
        ("residencial", "evening", "exterior"): 60.0,
        # Comercial
        ("comercial", "diurno", "interior"): 40.0,
        ("comercial", "diurno", "exterior"): 70.0,
        ("comercial", "nocturno", "interior"): 35.0,
        ("comercial", "nocturno", "exterior"): 60.0,
        ("comercial", "evening", "interior"): 38.0,
        ("comercial", "evening", "exterior"): 65.0,
        # Industrial
        ("industrial", "diurno", "interior"): 45.0,
        ("industrial", "diurno", "exterior"): 75.0,
        ("industrial", "nocturno", "interior"): 40.0,
        ("industrial", "nocturno", "exterior"): 65.0,
        ("industrial", "evening", "interior"): 43.0,
        ("industrial", "evening", "exterior"): 70.0,
    },
)

# ---------------------------------------------------------------------------
# Madrid
# ---------------------------------------------------------------------------
_add_city(
    municipality="Madrid",
    regulation_name="Ordenanza de Protección contra la Contaminación Acústica de Madrid",
    article="Art. 14",
    limits={
        ("residencial", "diurno", "interior"): 35.0,
        ("residencial", "diurno", "exterior"): 65.0,
        ("residencial", "nocturno", "interior"): 30.0,
        ("residencial", "nocturno", "exterior"): 55.0,
        ("residencial", "evening", "interior"): 33.0,
        ("residencial", "evening", "exterior"): 60.0,
        ("comercial", "diurno", "interior"): 40.0,
        ("comercial", "diurno", "exterior"): 70.0,
        ("comercial", "nocturno", "interior"): 35.0,
        ("comercial", "nocturno", "exterior"): 60.0,
        ("industrial", "diurno", "interior"): 45.0,
        ("industrial", "diurno", "exterior"): 75.0,
        ("industrial", "nocturno", "interior"): 40.0,
        ("industrial", "nocturno", "exterior"): 65.0,
    },
)

# ---------------------------------------------------------------------------
# Barcelona
# ---------------------------------------------------------------------------
_add_city(
    municipality="Barcelona",
    regulation_name="Ordenança del medi ambient de Barcelona",
    article="Art. 48",
    limits={
        ("residencial", "diurno", "interior"): 35.0,
        ("residencial", "diurno", "exterior"): 60.0,
        ("residencial", "nocturno", "interior"): 30.0,
        ("residencial", "nocturno", "exterior"): 50.0,
        ("residencial", "evening", "interior"): 32.0,
        ("residencial", "evening", "exterior"): 55.0,
        ("comercial", "diurno", "interior"): 40.0,
        ("comercial", "diurno", "exterior"): 65.0,
        ("comercial", "nocturno", "interior"): 35.0,
        ("comercial", "nocturno", "exterior"): 55.0,
        ("industrial", "diurno", "interior"): 45.0,
        ("industrial", "diurno", "exterior"): 70.0,
        ("industrial", "nocturno", "interior"): 40.0,
        ("industrial", "nocturno", "exterior"): 60.0,
    },
)

# ---------------------------------------------------------------------------
# Valencia
# ---------------------------------------------------------------------------
_add_city(
    municipality="Valencia",
    regulation_name="Ordenanza municipal de protección contra la contaminación acústica de Valencia",
    article="Art. 36",
    limits={
        ("residencial", "diurno", "interior"): 35.0,
        ("residencial", "diurno", "exterior"): 55.0,
        ("residencial", "nocturno", "interior"): 25.0,
        ("residencial", "nocturno", "exterior"): 45.0,
        ("residencial", "evening", "interior"): 30.0,
        ("residencial", "evening", "exterior"): 50.0,
        ("comercial", "diurno", "interior"): 40.0,
        ("comercial", "diurno", "exterior"): 65.0,
        ("comercial", "nocturno", "interior"): 30.0,
        ("comercial", "nocturno", "exterior"): 55.0,
        ("industrial", "diurno", "interior"): 45.0,
        ("industrial", "diurno", "exterior"): 70.0,
        ("industrial", "nocturno", "interior"): 35.0,
        ("industrial", "nocturno", "exterior"): 60.0,
    },
)

# ---------------------------------------------------------------------------
# Sevilla
# ---------------------------------------------------------------------------
_add_city(
    municipality="Sevilla",
    regulation_name="Ordenanza municipal contra ruidos y vibraciones de Sevilla",
    article="Art. 22",
    limits={
        ("residencial", "diurno", "interior"): 35.0,
        ("residencial", "diurno", "exterior"): 60.0,
        ("residencial", "nocturno", "interior"): 30.0,
        ("residencial", "nocturno", "exterior"): 50.0,
        ("comercial", "diurno", "interior"): 40.0,
        ("comercial", "diurno", "exterior"): 65.0,
        ("comercial", "nocturno", "interior"): 35.0,
        ("comercial", "nocturno", "exterior"): 55.0,
        ("industrial", "diurno", "interior"): 45.0,
        ("industrial", "diurno", "exterior"): 70.0,
        ("industrial", "nocturno", "interior"): 40.0,
        ("industrial", "nocturno", "exterior"): 60.0,
    },
)

# ---------------------------------------------------------------------------
# Zaragoza
# ---------------------------------------------------------------------------
_add_city(
    municipality="Zaragoza",
    regulation_name="Ordenanza municipal de protección contra la contaminación acústica de Zaragoza",
    article="Art. 18",
    limits={
        ("residencial", "diurno", "interior"): 35.0,
        ("residencial", "diurno", "exterior"): 60.0,
        ("residencial", "nocturno", "interior"): 25.0,
        ("residencial", "nocturno", "exterior"): 50.0,
        ("comercial", "diurno", "interior"): 40.0,
        ("comercial", "diurno", "exterior"): 65.0,
        ("comercial", "nocturno", "interior"): 35.0,
        ("comercial", "nocturno", "exterior"): 55.0,
        ("industrial", "diurno", "interior"): 45.0,
        ("industrial", "diurno", "exterior"): 70.0,
        ("industrial", "nocturno", "interior"): 40.0,
        ("industrial", "nocturno", "exterior"): 60.0,
    },
)

# ---------------------------------------------------------------------------
# Málaga
# ---------------------------------------------------------------------------
_add_city(
    municipality="Málaga",
    regulation_name="Ordenanza municipal de protección del medio ambiente contra ruidos y vibraciones de Málaga",
    article="Art. 25",
    limits={
        ("residencial", "diurno", "interior"): 35.0,
        ("residencial", "diurno", "exterior"): 60.0,
        ("residencial", "nocturno", "interior"): 25.0,
        ("residencial", "nocturno", "exterior"): 50.0,
        ("residencial", "evening", "interior"): 30.0,
        ("residencial", "evening", "exterior"): 55.0,
        ("comercial", "diurno", "interior"): 40.0,
        ("comercial", "diurno", "exterior"): 65.0,
        ("comercial", "nocturno", "interior"): 35.0,
        ("comercial", "nocturno", "exterior"): 55.0,
        ("industrial", "diurno", "interior"): 45.0,
        ("industrial", "diurno", "exterior"): 70.0,
        ("industrial", "nocturno", "interior"): 40.0,
        ("industrial", "nocturno", "exterior"): 60.0,
    },
)

# ---------------------------------------------------------------------------
# Murcia
# ---------------------------------------------------------------------------
_add_city(
    municipality="Murcia",
    regulation_name="Ordenanza municipal de protección del medio ambiente contra el ruido de Murcia",
    article="Art. 20",
    limits={
        ("residencial", "diurno", "interior"): 35.0,
        ("residencial", "diurno", "exterior"): 60.0,
        ("residencial", "nocturno", "interior"): 25.0,
        ("residencial", "nocturno", "exterior"): 50.0,
        ("comercial", "diurno", "interior"): 40.0,
        ("comercial", "diurno", "exterior"): 65.0,
        ("comercial", "nocturno", "interior"): 35.0,
        ("comercial", "nocturno", "exterior"): 55.0,
        ("industrial", "diurno", "interior"): 45.0,
        ("industrial", "diurno", "exterior"): 70.0,
        ("industrial", "nocturno", "interior"): 40.0,
        ("industrial", "nocturno", "exterior"): 60.0,
    },
)

# ---------------------------------------------------------------------------
# Palma
# ---------------------------------------------------------------------------
_add_city(
    municipality="Palma",
    regulation_name="Ordenança municipal de protecció contra la contaminació acústica de Palma",
    article="Art. 16",
    limits={
        ("residencial", "diurno", "interior"): 35.0,
        ("residencial", "diurno", "exterior"): 60.0,
        ("residencial", "nocturno", "interior"): 25.0,
        ("residencial", "nocturno", "exterior"): 50.0,
        ("comercial", "diurno", "interior"): 40.0,
        ("comercial", "diurno", "exterior"): 65.0,
        ("comercial", "nocturno", "interior"): 35.0,
        ("comercial", "nocturno", "exterior"): 55.0,
        ("industrial", "diurno", "interior"): 45.0,
        ("industrial", "diurno", "exterior"): 70.0,
        ("industrial", "nocturno", "interior"): 40.0,
        ("industrial", "nocturno", "exterior"): 60.0,
    },
)

# ---------------------------------------------------------------------------
# Las Palmas
# ---------------------------------------------------------------------------
_add_city(
    municipality="Las Palmas",
    regulation_name="Ordenanza municipal sobre protección del medio ambiente contra la emisión de ruidos de Las Palmas de Gran Canaria",
    article="Art. 12",
    limits={
        ("residencial", "diurno", "interior"): 35.0,
        ("residencial", "diurno", "exterior"): 60.0,
        ("residencial", "nocturno", "interior"): 25.0,
        ("residencial", "nocturno", "exterior"): 50.0,
        ("comercial", "diurno", "interior"): 40.0,
        ("comercial", "diurno", "exterior"): 65.0,
        ("comercial", "nocturno", "interior"): 35.0,
        ("comercial", "nocturno", "exterior"): 55.0,
        ("industrial", "diurno", "interior"): 45.0,
        ("industrial", "diurno", "exterior"): 70.0,
        ("industrial", "nocturno", "interior"): 40.0,
        ("industrial", "nocturno", "exterior"): 60.0,
    },
)

# ---------------------------------------------------------------------------
# Bilbao
# ---------------------------------------------------------------------------
_add_city(
    municipality="Bilbao",
    regulation_name="Ordenanza municipal de protección del medio ambiente contra la contaminación por ruidos y vibraciones de Bilbao",
    article="Art. 19",
    limits={
        ("residencial", "diurno", "interior"): 35.0,
        ("residencial", "diurno", "exterior"): 60.0,
        ("residencial", "nocturno", "interior"): 25.0,
        ("residencial", "nocturno", "exterior"): 50.0,
        ("residencial", "evening", "interior"): 30.0,
        ("residencial", "evening", "exterior"): 55.0,
        ("comercial", "diurno", "interior"): 40.0,
        ("comercial", "diurno", "exterior"): 65.0,
        ("comercial", "nocturno", "interior"): 35.0,
        ("comercial", "nocturno", "exterior"): 55.0,
        ("industrial", "diurno", "interior"): 45.0,
        ("industrial", "diurno", "exterior"): 70.0,
        ("industrial", "nocturno", "interior"): 40.0,
        ("industrial", "nocturno", "exterior"): 60.0,
    },
)

# ---------------------------------------------------------------------------
# Alicante
# ---------------------------------------------------------------------------
_add_city(
    municipality="Alicante",
    regulation_name="Ordenanza municipal reguladora del ruido y las vibraciones de Alicante",
    article="Art. 24",
    limits={
        ("residencial", "diurno", "interior"): 35.0,
        ("residencial", "diurno", "exterior"): 55.0,
        ("residencial", "nocturno", "interior"): 25.0,
        ("residencial", "nocturno", "exterior"): 45.0,
        ("comercial", "diurno", "interior"): 40.0,
        ("comercial", "diurno", "exterior"): 65.0,
        ("comercial", "nocturno", "interior"): 30.0,
        ("comercial", "nocturno", "exterior"): 55.0,
        ("industrial", "diurno", "interior"): 45.0,
        ("industrial", "diurno", "exterior"): 70.0,
        ("industrial", "nocturno", "interior"): 35.0,
        ("industrial", "nocturno", "exterior"): 60.0,
    },
)

# ---------------------------------------------------------------------------
# Córdoba
# ---------------------------------------------------------------------------
_add_city(
    municipality="Córdoba",
    regulation_name="Ordenanza municipal de protección contra la contaminación acústica de Córdoba",
    article="Art. 21",
    limits={
        ("residencial", "diurno", "interior"): 35.0,
        ("residencial", "diurno", "exterior"): 60.0,
        ("residencial", "nocturno", "interior"): 25.0,
        ("residencial", "nocturno", "exterior"): 50.0,
        ("comercial", "diurno", "interior"): 40.0,
        ("comercial", "diurno", "exterior"): 65.0,
        ("comercial", "nocturno", "interior"): 35.0,
        ("comercial", "nocturno", "exterior"): 55.0,
        ("industrial", "diurno", "interior"): 45.0,
        ("industrial", "diurno", "exterior"): 70.0,
        ("industrial", "nocturno", "interior"): 40.0,
        ("industrial", "nocturno", "exterior"): 60.0,
    },
)

# ---------------------------------------------------------------------------
# Valladolid
# ---------------------------------------------------------------------------
_add_city(
    municipality="Valladolid",
    regulation_name="Ordenanza municipal de protección del medio ambiente acústico de Valladolid",
    article="Art. 15",
    limits={
        ("residencial", "diurno", "interior"): 35.0,
        ("residencial", "diurno", "exterior"): 60.0,
        ("residencial", "nocturno", "interior"): 25.0,
        ("residencial", "nocturno", "exterior"): 50.0,
        ("comercial", "diurno", "interior"): 40.0,
        ("comercial", "diurno", "exterior"): 65.0,
        ("comercial", "nocturno", "interior"): 35.0,
        ("comercial", "nocturno", "exterior"): 55.0,
        ("industrial", "diurno", "interior"): 45.0,
        ("industrial", "diurno", "exterior"): 70.0,
        ("industrial", "nocturno", "interior"): 40.0,
        ("industrial", "nocturno", "exterior"): 60.0,
    },
)

# ---------------------------------------------------------------------------
# Vigo
# ---------------------------------------------------------------------------
_add_city(
    municipality="Vigo",
    regulation_name="Ordenanza municipal de protección contra a contaminación acústica de Vigo",
    article="Art. 17",
    limits={
        ("residencial", "diurno", "interior"): 35.0,
        ("residencial", "diurno", "exterior"): 60.0,
        ("residencial", "nocturno", "interior"): 25.0,
        ("residencial", "nocturno", "exterior"): 50.0,
        ("comercial", "diurno", "interior"): 40.0,
        ("comercial", "diurno", "exterior"): 65.0,
        ("comercial", "nocturno", "interior"): 35.0,
        ("comercial", "nocturno", "exterior"): 55.0,
        ("industrial", "diurno", "interior"): 45.0,
        ("industrial", "diurno", "exterior"): 70.0,
        ("industrial", "nocturno", "interior"): 40.0,
        ("industrial", "nocturno", "exterior"): 60.0,
    },
)

# ---------------------------------------------------------------------------
# Gijón
# ---------------------------------------------------------------------------
_add_city(
    municipality="Gijón",
    regulation_name="Ordenanza municipal de protección del medio ambiente contra ruidos y vibraciones de Gijón",
    article="Art. 23",
    limits={
        ("residencial", "diurno", "interior"): 35.0,
        ("residencial", "diurno", "exterior"): 60.0,
        ("residencial", "nocturno", "interior"): 25.0,
        ("residencial", "nocturno", "exterior"): 50.0,
        ("residencial", "evening", "interior"): 30.0,
        ("residencial", "evening", "exterior"): 55.0,
        ("comercial", "diurno", "interior"): 40.0,
        ("comercial", "diurno", "exterior"): 65.0,
        ("comercial", "nocturno", "interior"): 35.0,
        ("comercial", "nocturno", "exterior"): 55.0,
        ("industrial", "diurno", "interior"): 45.0,
        ("industrial", "diurno", "exterior"): 70.0,
        ("industrial", "nocturno", "interior"): 40.0,
        ("industrial", "nocturno", "exterior"): 60.0,
    },
)
