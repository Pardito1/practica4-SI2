#!/bin/bash
# Script de configuración rápida del balanceador en VM1
# Ejecutar como root o con sudo en VM1
#
# USO: sudo bash setup_balancer_vm1.sh

echo "=== Configuración del Balanceador Apache - Práctica 4 SI2 ==="

# 1. Añadir Listen 18080 si no existe
echo "[1/5] Configurando puerto 18080..."
if ! grep -q "Listen 18080" /etc/apache2/ports.conf; then
    echo "Listen 18080" | sudo tee -a /etc/apache2/ports.conf
    echo "  -> Añadido Listen 18080 a ports.conf"
else
    echo "  -> Listen 18080 ya existe en ports.conf"
fi

# 2. Habilitar módulos necesarios
echo "[2/5] Habilitando módulos Apache..."
sudo a2enmod proxy proxy_balancer proxy_http lbmethod_byrequests headers rewrite

# 3. Copiar configuración (asume que 000-default.conf ya está en el directorio actual)
echo "[3/5] Copiando configuración..."
sudo cp 000-default.conf /etc/apache2/sites-available/000-default.conf

# 4. Verificar configuración
echo "[4/5] Verificando configuración..."
sudo apachectl configtest

# 5. Reiniciar Apache
echo "[5/5] Reiniciando Apache..."
sudo systemctl restart apache2.service

echo ""
echo "=== Verificación ==="
sudo systemctl status apache2 --no-pager
echo ""
echo "Accede a http://localhost:18080/balancer-manager para verificar el balanceador"
