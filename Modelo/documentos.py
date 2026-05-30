from __future__ import annotations

from dataclasses import dataclass, field
from datetime import date, datetime
from decimal import Decimal

from .base import ModeloBase


@dataclass(slots=True, kw_only=True)
class EntradaDetalle(ModeloBase):
    tabla = "entrada_d"
    pk = "income_detail_id"

    income_detail_id: int
    income_id: int
    line_id: int
    product_id: int
    quantity: Decimal
    cost: Decimal


@dataclass(slots=True, kw_only=True)
class EntradaCabecera(ModeloBase):
    tabla = "entrada_c"
    pk = "income_id"

    income_id: int
    user_id: int
    tipo_ingreso: str = "COMPRA"
    system_date: datetime | None = None
    reposicion_id: int | None = None
    detalles: list[EntradaDetalle] = field(default_factory=list)


@dataclass(slots=True, kw_only=True)
class EntregaDetalle(ModeloBase):
    tabla = "entregas_d"
    pk = "delivery_detail_id"

    delivery_detail_id: int
    delivery_id: int
    line_id: int
    product_id: int
    quantity: Decimal


@dataclass(slots=True, kw_only=True)
class EntregaCabecera(ModeloBase):
    tabla = "entregas_c"
    pk = "delivery_id"

    delivery_id: int
    user_id: int
    system_date: datetime | None = None
    delivery_date: date | None = None
    reserv_id: int | None = None
    detalles: list[EntregaDetalle] = field(default_factory=list)


@dataclass(slots=True, kw_only=True)
class OrdenReposicionDetalle(ModeloBase):
    tabla = "orden_reposicion_d"
    pk = "reposicion_detail_id"

    reposicion_detail_id: int
    reposicion_id: int
    line_id: int
    product_id: int
    quantity: Decimal
    price: Decimal
    subtotal: Decimal | None = None
    comment: str | None = None


@dataclass(slots=True, kw_only=True)
class OrdenReposicionCabecera(ModeloBase):
    tabla = "orden_reposicion_c"
    pk = "reposicion_id"

    reposicion_id: int
    user_id: int
    status: str = "O"
    tipo_ingreso: str = "COMPRA"
    needed_date: date | None = None
    system_date: datetime | None = None
    comment: str | None = None
    detalles: list[OrdenReposicionDetalle] = field(default_factory=list)


@dataclass(slots=True, kw_only=True)
class ReservaDetalle(ModeloBase):
    tabla = "reservas_d"
    pk = "reserve_detail_id"

    reserve_detail_id: int
    reserv_id: int
    line_id: int
    product_id: int
    quantity: Decimal


@dataclass(slots=True, kw_only=True)
class ReservaCabecera(ModeloBase):
    tabla = "reservas_c"
    pk = "reserv_id"

    reserv_id: int
    user_id: int
    planning_date: date
    status: str
    system_date: datetime | None = None
    detalles: list[ReservaDetalle] = field(default_factory=list)


@dataclass(slots=True, kw_only=True)
class SalidaDetalle(ModeloBase):
    tabla = "salida_d"
    pk = "exit_detail_id"

    exit_detail_id: int
    exit_id: int
    line_id: int
    product_id: int
    quantity: Decimal
    price: Decimal
    reserv_id: int | None = None


@dataclass(slots=True, kw_only=True)
class SalidaCabecera(ModeloBase):
    tabla = "salida_c"
    pk = "exit_id"

    exit_id: int
    user_id: int
    system_date: datetime | None = None
    detalles: list[SalidaDetalle] = field(default_factory=list)

