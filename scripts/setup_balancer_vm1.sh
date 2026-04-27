#!/bin/bash
# Script de configuración rápida del balanceador en VM1
# Ejecutar como root o con sudo en VM1
#
# Apache escucha en el puerto 80 dentro de la VM. El PC host
# port-forwardea host:18080 -> VM1:80 (definido por VirtualBox NAT).
#
# USO: sudo bash setup_balancer_vm1.sh

echo "=== Configuración del Balanceador Apache - Práctica 4 SI2 ==="

# 1. Habilitar módulos necesarios
echo "[1/4] Habilitando módulos Apache..."
sudo a2enmod proxy proxy_balancer proxy_http lbmethod_byrequests headers rewrite

# 2. Copiar configuración (asume que 000-default.conf ya está en el directorio actual)
echo "[2/4] Copiando configuración..."
sudo cp 000-default.conf /etc/apache2/sites-available/000-default.conf

# 3. Verificar configuración
echo "[3/4] Verificando configuración..."
sudo apachectl configtest

# 4. Reiniciar Apache
echo "[4/4] Reiniciando Apache..."
sudo systemctl restart apache2.service

echo ""
echo "=== Verificación ==="
sudo systemctl status apache2 --no-pager
echo ""
echo "Desde el PC host, accede a:"
echo "  http://localhost:18080/balancer-manager"
echo "  http://localhost:18080/P1base/visaApp/tarjeta/"
