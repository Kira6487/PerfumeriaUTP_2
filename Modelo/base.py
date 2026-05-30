from __future__ import annotations

from dataclasses import asdict, dataclass, fields
from typing import Any, ClassVar


@dataclass(slots=True, kw_only=True)
class ModeloBase:
    """Base comun para objetos que representan tablas de PostgreSQL."""

    tabla: ClassVar[str]
    pk: ClassVar[str | tuple[str, ...]]

    @classmethod
    def desde_dict(cls, datos: dict[str, Any]):
        nombres = {campo.name for campo in fields(cls)}
        return cls(**{clave: valor for clave, valor in datos.items() if clave in nombres})

    def a_dict(self) -> dict[str, Any]:
        return asdict(self)

    def valor_pk(self) -> Any:
        if isinstance(self.pk, tuple):
            return tuple(getattr(self, columna) for columna in self.pk)
        return getattr(self, self.pk)

