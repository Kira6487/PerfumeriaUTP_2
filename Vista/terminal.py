from __future__ import annotations

from datetime import date
from decimal import Decimal
from getpass import getpass

import psycopg

from Controlador.autenticacion import (
    SesionUsuario,
    crear_usuario,
    iniciar_sesion,
    instalar_funciones_autenticacion,
)
from Controlador.procesos import (
    DetalleMovimiento,
    aprobar_orden_reposicion,
    aprobar_reserva,
    cancelar_orden_reposicion,
    cancelar_reserva,
    crear_orden_reposicion,
    crear_reserva,
    entregar_reserva,
    generar_entrada_desde_reposicion,
    instalar_funciones_procesos,
    obtener_stock_producto,
)


def main() -> None:
    instalar_funciones_autenticacion()
    instalar_funciones_procesos()

    sesion: SesionUsuario | None = None

    while True:
        print("\n=== Perfumeria UTP ===")
        if sesion:
            print(f"Sesion: {sesion.nombre_completo} ({sesion.role_name})")
            print("1. Crear reserva")
            print("2. Crear orden de reposicion")
            if sesion.admin:
                print("3. Aprobar reserva")
                print("4. Registrar entrega desde reserva")
                print("5. Cancelar reserva")
                print("6. Aprobar orden de reposicion")
                print("7. Generar entrada desde reposicion")
                print("8. Cancelar orden de reposicion")
            print("9. Cerrar sesion")
        else:
            print("1. Iniciar sesion")
            print("2. Registrarse")
        print("0. Salir")

        opcion = input("Opcion: ").strip()

        try:
            if not sesion:
                sesion = _menu_sin_sesion(opcion)
            else:
                sesion = _menu_con_sesion(opcion, sesion)
        except (psycopg.Error, ValueError, RuntimeError) as error:
            print(f"Error: {error}")

        if opcion == "0":
            break


def _menu_sin_sesion(opcion: str) -> SesionUsuario | None:
    if opcion == "1":
        sesion = _iniciar_sesion_terminal()
        if sesion:
            print(f"Bienvenido/a, {sesion.nombre_completo}. Rol: {sesion.role_name}")
            return sesion

        print("Usuario o contrasena incorrectos.")
        return None

    if opcion == "2":
        usuario = _registrar_usuario_terminal()
        print(f"Usuario creado correctamente con ID {usuario.user_id}.")
        return None

    if opcion == "0":
        return None

    print("Opcion no valida.")
    return None


def _menu_con_sesion(opcion: str, sesion: SesionUsuario) -> SesionUsuario | None:
    if opcion == "1":
        reserv_id = _crear_reserva_terminal(sesion.user_id)
        print(f"Reserva creada con ID {reserv_id} en estado O.")
    elif opcion == "2":
        reposicion_id = _crear_orden_reposicion_terminal(sesion.user_id)
        print(f"Orden de reposicion creada con ID {reposicion_id} en estado O.")
    elif opcion == "3" and sesion.admin:
        reserv_id = _entero("Reserva ID")
        aprobar_reserva(admin_user_id=sesion.user_id, reserv_id=reserv_id)
        print(f"Reserva {reserv_id} aprobada. El stock comprometido fue actualizado.")
    elif opcion == "4" and sesion.admin:
        reserv_id = _entero("Reserva ID")
        delivery_date = _fecha_opcional("Fecha de entrega (YYYY-MM-DD)") or date.today()
        delivery_id = entregar_reserva(
            admin_user_id=sesion.user_id,
            reserv_id=reserv_id,
            delivery_date=delivery_date,
        )
        print(f"Entrega {delivery_id} generada. La reserva {reserv_id} quedo cerrada.")
    elif opcion == "5" and sesion.admin:
        reserv_id = _entero("Reserva ID")
        cancelar_reserva(admin_user_id=sesion.user_id, reserv_id=reserv_id)
        print(f"Reserva {reserv_id} cancelada.")
    elif opcion == "6" and sesion.admin:
        reposicion_id = _entero("Orden de reposicion ID")
        aprobar_orden_reposicion(admin_user_id=sesion.user_id, reposicion_id=reposicion_id)
        print(f"Orden de reposicion {reposicion_id} aprobada. El stock pedido fue actualizado.")
    elif opcion == "7" and sesion.admin:
        reposicion_id = _entero("Orden de reposicion ID")
        income_id = generar_entrada_desde_reposicion(
            admin_user_id=sesion.user_id,
            reposicion_id=reposicion_id,
        )
        print(f"Entrada {income_id} generada. La orden {reposicion_id} quedo cerrada.")
    elif opcion == "8" and sesion.admin:
        reposicion_id = _entero("Orden de reposicion ID")
        cancelar_orden_reposicion(admin_user_id=sesion.user_id, reposicion_id=reposicion_id)
        print(f"Orden de reposicion {reposicion_id} cancelada.")
    elif opcion == "9":
        print("Sesion cerrada.")
        return None
    elif opcion == "0":
        return sesion
    else:
        print("Opcion no valida.")

    return sesion


def _registrar_usuario_terminal():
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


def _iniciar_sesion_terminal() -> SesionUsuario | None:
    print("\n=== Inicio de sesion ===")
    user_name = input("Usuario: ").strip()
    user_password = getpass("Contrasena: ")
    return iniciar_sesion(user_name, user_password)


def _crear_reserva_terminal(user_id: int) -> int:
    print("\n=== Crear reserva ===")
    planning_date = _fecha("Fecha planificada (YYYY-MM-DD)")
    detalles = _leer_detalles(incluir_precio=False)

    try:
        return crear_reserva(user_id=user_id, planning_date=planning_date, detalles=detalles)
    except psycopg.Error as error:
        print("No se pudo crear la reserva. Si falta stock, genera una orden de reposicion.")
        raise error


def _crear_orden_reposicion_terminal(user_id: int) -> int:
    print("\n=== Crear orden de reposicion ===")
    needed_date = _fecha_opcional("Fecha requerida (YYYY-MM-DD)")
    tipo_ingreso = input("Tipo de ingreso [COMPRA]: ").strip() or "COMPRA"
    comment = _texto_opcional("Comentario")
    detalles = _leer_detalles(incluir_precio=True)
    return crear_orden_reposicion(
        user_id=user_id,
        needed_date=needed_date,
        tipo_ingreso=tipo_ingreso,
        comment=comment,
        detalles=detalles,
    )


def _leer_detalles(*, incluir_precio: bool) -> list[DetalleMovimiento]:
    detalles: list[DetalleMovimiento] = []

    while True:
        product_id = _entero("Producto ID")
        cantidad = _decimal("Cantidad")
        precio = _decimal("Precio/costo") if incluir_precio else None
        comentario = _texto_opcional("Comentario de linea") if incluir_precio else None

        stock = obtener_stock_producto(product_id)
        if stock:
            print(
                "Stock actual:"
                f" fisico={stock['stock']}, disponible={stock['disponible']},"
                f" comprometido={stock['comprometido']}, pedido={stock['pedido']}"
            )

        detalles.append(
            DetalleMovimiento(
                product_id=product_id,
                quantity=cantidad,
                price=precio,
                comment=comentario,
            )
        )

        if not _booleano("Agregar otra linea", default=False):
            break

    return detalles


def _texto_opcional(etiqueta: str) -> str | None:
    valor = input(f"{etiqueta} (opcional): ").strip()
    return valor or None


def _entero(etiqueta: str) -> int:
    return int(input(f"{etiqueta}: ").strip())


def _entero_opcional(etiqueta: str) -> int | None:
    valor = input(f"{etiqueta} (opcional): ").strip()
    return int(valor) if valor else None


def _decimal(etiqueta: str) -> Decimal:
    return Decimal(input(f"{etiqueta}: ").strip())


def _fecha(etiqueta: str) -> date:
    return date.fromisoformat(input(f"{etiqueta}: ").strip())


def _fecha_opcional(etiqueta: str) -> date | None:
    valor = input(f"{etiqueta} (opcional): ").strip()
    return date.fromisoformat(valor) if valor else None


def _booleano(etiqueta: str, *, default: bool) -> bool:
    sugerido = "S/n" if default else "s/N"
    valor = input(f"{etiqueta}? ({sugerido}): ").strip().lower()

    if not valor:
        return default
    return valor in {"s", "si", "sí", "y", "yes", "true", "1"}


if __name__ == "__main__":
    main()
