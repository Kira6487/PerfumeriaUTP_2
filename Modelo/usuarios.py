from __future__ import annotations

from dataclasses import dataclass
from datetime import date

from .base import ModeloBase


@dataclass(slots=True, kw_only=True)
class Usuario(ModeloBase):
    tabla = "usuarios"
    pk = "user_id"

    user_id: int
    user_name: str
    user_password: str
    u_pnombre: str
    u_papellido: str
    role_id: int
    u_snombre: str | None = None
    u_sapellido: str | None = None
    u_fechanacimiento: date | None = None
    u_edad: int | None = None
    gender_id: int | None = None
    u_correo: str | None = None
    u_telefono: str | None = None
    u_estudianteutp: bool | None = None

