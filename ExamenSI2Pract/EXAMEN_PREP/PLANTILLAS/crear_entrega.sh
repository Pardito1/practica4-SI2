#!/bin/bash
# crear_entrega.sh — empaqueta la carpeta del examen en .tar.gz limpio
# Uso: bash crear_entrega.sh
# Se ejecuta DENTRO de la carpeta SI2EXTxPyyApellido1Apellido2Nombre/

set -e

CARPETA=$(basename "$PWD")
DESTINO_TAR="../${CARPETA}.tar.gz"

echo "==> Carpeta del examen: $CARPETA"
echo "==> Destino: $DESTINO_TAR"
echo ""

# 1. Verificar que estamos en la carpeta correcta
if [[ ! "$CARPETA" =~ ^SI2EXT ]]; then
    echo "❌ ERROR: La carpeta actual no empieza por 'SI2EXT'. ¿Estás en el sitio correcto?"
    echo "   PWD: $PWD"
    exit 1
fi

# 2. Listar lo que vamos a meter
echo "==> Contenido actual de $CARPETA:"
ls -la
echo ""

# 3. Avisar si faltan ficheros típicos
for f in Ejercicio1.txt Ejercicio2.txt Ejercicio3.txt; do
    if [[ ! -f "$f" ]]; then
        echo "⚠️  WARNING: Falta $f"
    fi
done

# 4. Limpiar basura antes de empaquetar
echo ""
echo "==> Limpiando ficheros basura..."
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -type f -name "*.pyc" -delete 2>/dev/null || true
find . -type f -name "*.pyo" -delete 2>/dev/null || true
find . -type d -name "venv" -exec rm -rf {} + 2>/dev/null || true
find . -type d -name ".idea" -exec rm -rf {} + 2>/dev/null || true
find . -type d -name ".vscode" -exec rm -rf {} + 2>/dev/null || true
find . -type f -name ".DS_Store" -delete 2>/dev/null || true
find . -type f -name "*.swp" -delete 2>/dev/null || true
find . -type f -name "db.sqlite3" -delete 2>/dev/null || true
echo "   OK."

# 5. Salir un nivel y crear el .tar.gz
echo ""
echo "==> Creando $DESTINO_TAR..."
cd ..
tar -czvf "$(basename "$DESTINO_TAR")" "$CARPETA/" 2>&1 | head -20
echo "   ..."
echo ""

# 6. Verificar
echo "==> Verificación:"
ls -lh "$(basename "$DESTINO_TAR")"
echo ""
echo "==> Contenido del .tar.gz:"
tar -tzvf "$(basename "$DESTINO_TAR")" | head -20
TOTAL=$(tar -tzvf "$(basename "$DESTINO_TAR")" | wc -l)
echo "   ..."
echo "   ($TOTAL ficheros en total)"
echo ""

SIZE=$(du -h "$(basename "$DESTINO_TAR")" | cut -f1)
echo "==> Tamaño: $SIZE"
echo ""

# 7. Avisos finales
if [[ -d "$CARPETA/__pycache__" ]] || tar -tzvf "$(basename "$DESTINO_TAR")" | grep -q "__pycache__"; then
    echo "⚠️  WARNING: Hay __pycache__ en el .tar.gz. Revisa."
fi

echo "✅ ENTREGA LISTA."
echo ""
echo "Próximos pasos:"
echo "  1. Subir $DESTINO_TAR a Moodle"
echo "  2. Hacer copia de seguridad en pendrive:"
echo "     cp $(realpath "$(basename "$DESTINO_TAR")") /media/\$USER/PENDRIVE/"
