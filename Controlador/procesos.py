from __future__ import annotations

from dataclasses import asdict, dataclass
from datetime import date
from decimal import Decimal
from pathlib import Path
from typing import Any

from psycopg.types.json import Jsonb

from BD.conexion_bd import bd


ENDPOINTS_PROCESOS = {
    "crear_reserva": "POST /api/reservas",
    "aprobar_reserva": "PATCH /api/reservas/{reserv_id}/aprobar",
    "entregar_reserva": "POST /api/reservas/{reserv_id}/entrega",
    "cancelar_reserva": "PATCH /api/reservas/{reserv_id}/cancelar",
    "crear_orden_reposicion": "POST /api/reposiciones",
    "aprobar_orden_reposicion": "PATCH /api/reposiciones/{reposicion_id}/aprobar",
    "generar_entrada_reposicion": "POST /api/reposiciones/{reposicion_id}/entrada",
    "cancelar_orden_reposicion": "PATCH /api/reposiciones/{reposicion_id}/cancelar",
}


@dataclass(slots=True)
class DetalleMovimiento:
    product_id: int
    quantity: Decimal
    price: Decimal | None = None
    comment: str | None = None

    def a_dict(self) -> dict[str, Any]:
        datos = asdict(self)
        return {clave: valor for clave, valor in datos.items() if valor is not None}


def instalar_funciones_procesos() -> None:
    ruta_sql = Path(__file__).resolve().parents[1] / "BD" / "funciones_procesos.sql"
    bd.ejecutar(ruta_sql.read_text(encoding="utf-8"))


def crear_reserva(
    *,
    user_id: int,
    planning_date: date,
    detalles: list[DetalleMovimiento | dict[str, Any]],
) -> int:
    return _llamar_sp_id("sp_crear_reserva", [user_id, planning_date, _detalles_json(detalles)])


def aprobar_reserva(*, admin_user_id: int, reserv_id: int) -> int:
    return _llamar_sp_id("sp_aprobar_reserva", [admin_user_id, reserv_id])


def entregar_reserva(
    *,
    admin_user_id: int,
    reserv_id: int,
    delivery_date: date | None = None,
) -> int:
    return _llamar_sp_id("sp_crear_entrega_desde_reserva", [admin_user_id, reserv_id, delivery_date or date.today()])


def cancelar_reserva(*, admin_user_id: int, reserv_id: int) -> int:
    return _llamar_sp_id("sp_cancelar_reserva", [admin_user_id, reserv_id])


def crear_orden_reposicion(
    *,
    user_id: int,
    detalles: list[DetalleMovimiento | dict[str, Any]],
    needed_date: date | None = None,
    tipo_ingreso: str = "COMPRA",
    comment: str | None = None,
) -> int:
    return _llamar_sp_id(
        "sp_crear_orden_reposicion",
        [user_id, needed_date, tipo_ingreso, comment, _detalles_json(detalles)],
    )


def aprobar_orden_reposicion(*, admin_user_id: int, reposicion_id: int) -> int:
    return _llamar_sp_id("sp_aprobar_orden_reposicion", [admin_user_id, reposicion_id])


def generar_entrada_desde_reposicion(*, admin_user_id: int, reposicion_id: int) -> int:
    return _llamar_sp_id("sp_crear_entrada_desde_reposicion", [admin_user_id, reposicion_id])


def cancelar_orden_reposicion(*, admin_user_id: int, reposicion_id: int) -> int:
    return _llamar_sp_id("sp_cancelar_orden_reposicion", [admin_user_id, reposicion_id])


def obtener_stock_producto(product_id: int) -> dict[str, Any] | None:
    filas = bd.consultar(
        """
        SELECT product_id, stock, disponible, comprometido, pedido, stock_min, stock_max
        FROM stock
        WHERE product_id = %s
        """,
        [product_id],
    )
    return filas[0] if filas else None


def _llamar_sp_id(nombre: str, parametros: list[Any]) -> int:
    filas = bd.llamar_funcion(nombre, parametros)

    if not filas:
        raise RuntimeError(f"La funcion {nombre} no devolvio resultado.")

    return int(next(iter(filas[0].values())))


def _detalles_json(detalles: list[DetalleMovimiento | dict[str, Any]]) -> Jsonb:
    if not detalles:
        raise ValueError("Debe indicar al menos un detalle.")

    normalizados: list[dict[str, Any]] = []
    for detalle in detalles:
        datos = detalle.a_dict() if isinstance(detalle, DetalleMovimiento) else dict(detalle)
        normalizados.append(
            {
                clave: str(valor) if isinstance(valor, Decimal) else valor
                for clave, valor in datos.items()
                if valor is not None
            }
        )

    return Jsonb(normalizados)
