from __future__ import annotations

from dataclasses import dataclass
from decimal import Decimal

from .base import ModeloBase


@dataclass(slots=True, kw_only=True)
class Producto(ModeloBase):
    tabla = "productos"
    pk = "product_id"

    product_id: int
    product_name: str
    group_id: int
    brand_id: int
    family_id: int
    concent_id: int
    product_description: str | None = None
    gender_id: int | None = None
    volume: Decimal | None = None
    active: bool | None = None
    comment: str | None = None


@dataclass(slots=True, kw_only=True)
class Imagen(ModeloBase):
    tabla = "imagenes"
    pk = "image_id"

    image_id: int
    product_id: int
    image_name: str | None = None
    image_description: str | None = None
    url: str | None = None


@dataclass(slots=True, kw_only=True)
class Stock(ModeloBase):
    tabla = "stock"
    pk = "stock_id"

    stock_id: int
    product_id: int
    stock: Decimal | None = None
    price: Decimal | None = None
    cost: Decimal | None = None
    disponible: Decimal | None = None
    pedido: Decimal | None = None
    comprometido: Decimal | None = None
    stock_min: Decimal | None = None
    stock_max: Decimal | None = None

