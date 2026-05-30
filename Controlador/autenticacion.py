from __future__ import annotations

from dataclasses import asdict, dataclass
from datetime import date
from getpass import getpass
from pathlib import Path
from typing import Any

import psycopg

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


def registrar_usuario_terminal() -> Usuario:
    print("\n=== Registro de usuario ===")
    user_name = input("Usuario: ").strip()
    user_password = getpass("Contrasena: ")
    u_pnombre = input("Primer nombre: ").strip()
    u_snombre = _texto_opcional("Segundo nombre")
    u_papellido = input("Primer apellido: ").strip()
    u_sapellido = _texto_opcional("Segundo apellido")
    u_correo = _texto_opcional("Correo")
    u_telefono = _texto_opcional("Telefono")
    gender_id = _entero_opcional("Genero id (1=F, 2=M, 3=U)")
    u_fechanacimiento = _fecha_opcional("Fecha nacimiento (YYYY-MM-DD)")
    u_estudianteutp = _booleano("Estudiante UTP", default=True)

    return crear_usuario(
        user_name=user_name,
        user_password=user_password,
        u_pnombre=u_pnombre,
        u_snombre=u_snombre,
        u_papellido=u_papellido,
        u_sapellido=u_sapellido,
        u_fechanacimiento=u_fechanacimiento,
        gender_id=gender_id,
        u_correo=u_correo,
        u_telefono=u_telefono,
        u_estudianteutp=u_estudianteutp,
    )


def iniciar_sesion_terminal() -> SesionUsuario | None:
    print("\n=== Inicio de sesion ===")
    user_name = input("Usuario: ").strip()
    user_password = getpass("Contrasena: ")
    return iniciar_sesion(user_name, user_password)


def _texto_opcional(etiqueta: str) -> str | None:
    valor = input(f"{etiqueta} (opcional): ").strip()
    return valor or None


def _entero_opcional(etiqueta: str) -> int | None:
    valor = input(f"{etiqueta} (opcional): ").strip()
    return int(valor) if valor else None


def _fecha_opcional(etiqueta: str) -> date | None:
    valor = input(f"{etiqueta} (opcional): ").strip()
    return date.fromisoformat(valor) if valor else None


def _booleano(etiqueta: str, *, default: bool) -> bool:
    sugerido = "S/n" if default else "s/N"
    valor = input(f"{etiqueta}? ({sugerido}): ").strip().lower()

    if not valor:
        return default
    return valor in {"s", "si", "sí", "y", "yes", "true", "1"}


def main() -> None:
    instalar_funciones_autenticacion()

    while True:
        print("\n=== Perfumeria UTP ===")
        print("1. Iniciar sesion")
        print("2. Registrarse")
        print("0. Salir")
        opcion = input("Opcion: ").strip()

        try:
            if opcion == "1":
                sesion = iniciar_sesion_terminal()
                if sesion:
                    print(f"Bienvenido/a, {sesion.nombre_completo}. Rol: {sesion.role_name}")
                else:
                    print("Usuario o contrasena incorrectos.")
            elif opcion == "2":
                usuario = registrar_usuario_terminal()
                print(f"Usuario creado correctamente con ID {usuario.user_id}.")
            elif opcion == "0":
                break
            else:
                print("Opcion no valida.")
        except (psycopg.Error, ValueError, RuntimeError) as error:
            print(f"Error: {error}")


if __name__ == "__main__":
    main()
