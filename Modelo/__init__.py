"""Objetos de dominio basados en las tablas de PostgreSQL."""

from .actividad import Busqueda, Visita
from .base import ModeloBase
from .catalogos import Concentracion, Estado, Familia, Genero, Grupo, Marca, Rol
from .documentos import (
    EntradaCabecera,
    EntradaDetalle,
    EntregaCabecera,
    EntregaDetalle,
    OrdenReposicionCabecera,
    OrdenReposicionDetalle,
    ReservaCabecera,
    ReservaDetalle,
    SalidaCabecera,
    SalidaDetalle,
)
from .productos import Imagen, Producto, Stock
from .usuarios import Usuario

__all__ = [
    "ModeloBase",
    "Busqueda",
    "Visita",
    "Concentracion",
    "Estado",
    "Familia",
    "Genero",
    "Grupo",
    "Marca",
    "Rol",
    "Producto",
    "Imagen",
    "Stock",
    "Usuario",
    "EntradaCabecera",
    "EntradaDetalle",
    "EntregaCabecera",
    "EntregaDetalle",
    "OrdenReposicionCabecera",
    "OrdenReposicionDetalle",
    "ReservaCabecera",
    "ReservaDetalle",
    "SalidaCabecera",
    "SalidaDetalle",
]
