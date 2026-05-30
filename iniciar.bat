@echo off
cd /d "%~dp0"

if not exist ".venv\Scripts\python.exe" (
    echo No se encontro el entorno virtual .venv.
    echo Crea el entorno virtual o ejecuta desde VS Code con el entorno activo.
    pause
    exit /b 1
)

".venv\Scripts\python.exe" main.py
pause
