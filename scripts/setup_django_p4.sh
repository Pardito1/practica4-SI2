#!/bin/bash
# Script para aplicar los cambios de Django en cada VM
# Ejecutar en cada VM donde corra una instancia de Django
#
# USO: bash setup_django_p4.sh
# Asume que estás en el directorio P1-base/

echo "=== Aplicando cambios Django para Práctica 4 ==="

# 1. Aplicar migraciones (nuevo campo 'instancia' en modelo Pago)
echo "[1/3] Generando migraciones..."
python manage.py makemigrations

echo "[2/3] Aplicando migraciones a la base de datos..."
python manage.py migrate

# 3. Recopilar archivos estáticos
echo "[3/3] Recopilando archivos estáticos..."
python manage.py collectstatic --noinput

echo ""
echo "=== Listo ==="
echo "Reinicia gunicorn para que los cambios surtan efecto."
echo "Ejemplo: sudo systemctl restart gunicorn (o mata y relanza el proceso)"
