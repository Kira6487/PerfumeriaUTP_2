from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime

from .base import ModeloBase


@dataclass(slots=True, kw_only=True)
class Busqueda(ModeloBase):
    tabla = "busquedas"
    pk = "search_id"

    search_id: int
    user_id: int
    search_text: str
    search_date: datetime | None = None


@dataclass(slots=True, kw_only=True)
class Visita(ModeloBase):
    tabla = "visitas"
    pk = "visit_id"

    visit_id: int
    user_id: int
    product_id: int
    visit_date: datetime | None = None

