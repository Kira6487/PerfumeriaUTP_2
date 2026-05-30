# PerfumeriaUTP_2

Proyecto Final para el curso de Lenguajes de Programacion.

## Estructura

- `Modelo/`: clases y entidades del dominio.
- `Vista/`: interfaces de usuario.
- `Controlador/`: logica que conecta vista, modelo y base de datos.
- `BD/`: conexion y utilidades de PostgreSQL.
- `config/`: variables de configuracion local.
- `.venv/`: entorno virtual de Python.

## Conexion PostgreSQL

Instalar dependencias dentro del entorno virtual:

```powershell
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

Ejemplo de uso:

```python
from BD.conexion_bd import bd

filas = bd.consultar("SELECT * FROM productos")
bd.ejecutar("INSERT INTO auditoria(descripcion) VALUES (%s)", ["Prueba"])
resultado = bd.llamar_funcion("mi_funcion", [1, "texto"])
bd.llamar_procedimiento("mi_procedimiento", [10])
```
