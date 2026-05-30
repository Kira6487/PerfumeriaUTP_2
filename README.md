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

## Autenticacion

Endpoints previstos para conectar el front con el back:

- `POST /api/auth/registro`: crea un usuario nuevo llamando a `public.fn_crear_usuario`.
- `POST /api/auth/login`: valida credenciales y devuelve datos de sesion.

## Procesos de inventario y reservas

Endpoints previstos:

- `POST /api/reservas`: usuario crea una reserva en estado `O`.
- `PATCH /api/reservas/{reserv_id}/aprobar`: admin aprueba la reserva, pasa a `A` y afecta `stock.comprometido`.
- `POST /api/reservas/{reserv_id}/entrega`: admin genera entrega desde reserva aprobada; la reserva queda `C`, libera comprometido y resta stock fisico.
- `PATCH /api/reservas/{reserv_id}/cancelar`: admin cancela reserva `O` o `A`; si estaba aprobada libera comprometido.
- `POST /api/reposiciones`: usuario crea orden de reposicion en estado `O`.
- `PATCH /api/reposiciones/{reposicion_id}/aprobar`: admin aprueba la orden, pasa a `A` y afecta `stock.pedido`.
- `POST /api/reposiciones/{reposicion_id}/entrada`: admin genera entrada desde orden aprobada; la orden queda `C`, libera pedido y aumenta stock fisico.
- `PATCH /api/reposiciones/{reposicion_id}/cancelar`: admin cancela orden `O` o `A`; si estaba aprobada libera pedido.

Prueba por terminal:

```powershell
.\.venv\Scripts\python.exe main.py
```
