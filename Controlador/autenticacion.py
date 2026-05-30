from __future__ import annotations

from dataclasses import asdict, dataclass
from datetime import date
from pathlib import Path
from typing import Any

from BD.conexion_bd import bd
from Modelo import Usuario


ENDPOINTS_AUTENTICACION = {
    "registrar_usuario": "POST /api/auth/registro",
    "iniciar_sesion": "POST /api/auth/login",
}


@dataclass(slots=True)
class SesionUsuario:
    user_id: int
    user_name: str
    role_id: int
    role_name: str
    admin: bool
    nombre_completo: str

    def a_dict(self) -> dict[str, Any]:
        return asdict(self)


def instalar_funciones_autenticacion() -> None:
    ruta_sql = Path(__file__).resolve().parents[1] / "BD" / "funciones_autenticacion.sql"
    bd.ejecutar(ruta_sql.read_text(encoding="utf-8"))


def crear_usuario(
    *,
    user_name: str,
    user_password: str,
    u_pnombre: str,
    u_papellido: str,
    role_id: int = 1,
    u_snombre: str | None = None,
    u_sapellido: str | None = None,
    u_fechanacimiento: date | None = None,
    gender_id: int | None = None,
    u_correo: str | None = None,
    u_telefono: str | None = None,
    u_estudianteutp: bool = True,
) -> Usuario:
    filas = bd.llamar_funcion(
        "fn_crear_usuario",
        [
            user_name,
            user_password,
            u_pnombre,
            u_papellido,
            role_id,
            u_snombre,
            u_sapellido,
            u_fechanacimiento,
            gender_id,
            u_correo,
            u_telefono,
            u_estudianteutp,
        ],
    )

    if not filas:
        raise RuntimeError("La base de datos no devolvio el usuario creado.")

    datos = filas[0] | {"user_password": user_password}
    return Usuario.desde_dict(datos)


def iniciar_sesion(user_name: str, user_password: str) -> SesionUsuario | None:
    consulta = """
        SELECT
            u.user_id,
            u.user_name,
            u.role_id,
            r.role_name,
            COALESCE(r.admin, FALSE) AS admin,
            CONCAT_WS(' ', u.u_pnombre, u.u_snombre, u.u_papellido, u.u_sapellido) AS nombre_completo
        FROM usuarios u
        JOIN roles r ON r.role_id = u.role_id
        WHERE u.user_name = %s
          AND u.user_password = %s
        LIMIT 1
    """
    filas = bd.consultar(consulta, [user_name, user_password])

    if not filas:
        return None

    return SesionUsuario(**filas[0])
