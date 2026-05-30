from __future__ import annotations

from dataclasses import dataclass

from .base import ModeloBase


@dataclass(slots=True, kw_only=True)
class Concentracion(ModeloBase):
    tabla = "concentracion"
    pk = "concent_id"

    concent_id: int
    concent_name: str
    concent_description: str | None = None


@dataclass(slots=True, kw_only=True)
class Estado(ModeloBase):
    tabla = "estados"
    pk = "status"

    status: str
    description: str


@dataclass(slots=True, kw_only=True)
class Familia(ModeloBase):
    tabla = "familias"
    pk = "family_id"

    family_id: int
    family_name: str
    family_description: str | None = None


@dataclass(slots=True, kw_only=True)
class Genero(ModeloBase):
    tabla = "gender"
    pk = "gender_id"

    gender_id: int
    gender_name: str
    gender_description: str | None = None


@dataclass(slots=True, kw_only=True)
class Grupo(ModeloBase):
    tabla = "grupos"
    pk = "group_id"

    group_id: int
    group_name: str
    group_description: str | None = None


@dataclass(slots=True, kw_only=True)
class Marca(ModeloBase):
    tabla = "marcas"
    pk = "brand_id"

    brand_id: int
    brand_name: str
    brand_description: str | None = None
    brand_logo: str | None = None


@dataclass(slots=True, kw_only=True)
class Rol(ModeloBase):
    tabla = "roles"
    pk = "role_id"

    role_id: int
    role_name: str
    role_description: str | None = None
    admin: bool | None = None

