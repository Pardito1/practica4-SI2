# Instrucciones para el Lab - Práctica 4 SI2

## PASO 0: Subir el repo a GitHub (hacer en el Mac ANTES de ir al lab)

Abre Terminal en tu Mac y ejecuta:

```bash
# 1. El código Django ya está copiado en Practica 4 SI 2/si2_alumnos-main/
#    (lo copió Claude). Si no está, copiarlo manualmente:
#    cp -r "Practica 3 SI 2/si2_alumnos-main" "Practica 3 SI 2/Practica 4 SI 2/si2_alumnos-main"

# 2. Ir a la carpeta de Práctica 4
cd "/path/to/Practica 3 SI 2/Practica 4 SI 2"

# 3. Inicializar repo git
git init

# 4. Añadir TODO (el .gitignore excluye los proyectos de P3 que no necesitamos)
git add -A

# 5. Commit inicial
git commit -m "P4 SI2: código Django modificado + JMeter + config Apache + memoria borrador"

# 6. Crear repo privado en GitHub y subir
gh repo create practica4-si2 --private --source=. --remote=origin --push
```

Si no tienes `gh` instalado, crea el repo manualmente en github.com/new (privado, sin README) y luego:
```bash
git remote add origin https://github.com/Pardito1/practica4-si2.git
git branch -M main
git push -u origin main
```

---

## PASO 1: En el PC del lab - Clonar el repo

```bash
# Clonar el repo
git clone https://github.com/TU_USUARIO/practica4-si2.git
cd practica4-si2
```

---

## PASO 2: Averiguar las IPs de las VMs

```bash
# En cada VM, ejecutar:
ip addr show | grep "inet " | grep -v 127.0.0.1
# O también:
hostname -I
```

Apuntar:
- IP_VM1 = _______________
- IP_VM2 = _______________
- IP_VM3 = _______________

---

## PASO 3: Copiar código a las VMs

```bash
# Desde el PC del lab, copiar el código a cada VM:
scp -r si2_alumnos-main/P1-base/ usuario@IP_VM1:/path/to/P1-base/
scp -r si2_alumnos-main/P1-base/ usuario@IP_VM2:/path/to/P1-base/
scp -r si2_alumnos-main/P1-base/ usuario@IP_VM3:/path/to/P1-base/
```

---

## PASO 4: Aplicar migraciones (en VM1, con BD accesible)

```bash
ssh usuario@IP_VM1
cd /path/to/P1-base
python manage.py makemigrations visaApp
python manage.py migrate
```

---

## PASO 5: Configurar Apache en VM1

```bash
# Copiar config
scp scripts/000-default.conf usuario@IP_VM1:/tmp/

# En VM1:
ssh usuario@IP_VM1

# Editar IPs en el fichero
sudo nano /tmp/000-default.conf
# Cambiar ip_address → IP real de cada worker
# Cambiar XX.YY.ZZ.II → IP de VM1

# Copiar y activar
sudo cp /tmp/000-default.conf /etc/apache2/sites-available/000-default.conf

# Añadir Listen 18080
echo "Listen 18080" | sudo tee -a /etc/apache2/ports.conf

# Habilitar módulos
sudo a2enmod proxy proxy_balancer proxy_http lbmethod_byrequests headers rewrite

# Reiniciar
sudo systemctl restart apache2.service

# Verificar
sudo apachectl configtest
sudo systemctl status apache2
```

---

## PASO 6: Verificar que todo funciona

```bash
# Desde el PC del lab, acceder al balanceador:
curl http://IP_VM1:18080/P1base/visaApp/tarjeta/

# Debería devolver HTML del formulario de tarjeta
# Acceder a la consola: http://IP_VM1:18080/balancer-manager
```

---

## PASO 7: Ejecutar los ejercicios (usar Claude para ayuda)

Abre claude.ai en el navegador del lab y pega el prompt del fichero PROMPT_CLAUDE_LAB.md

---

## Consultas SQL útiles para los ejercicios

```sql
-- Ver todos los pagos con instancia
SELECT id, "idComercio", "idTransaccion", instancia, "marcaTiempo" 
FROM pago ORDER BY "marcaTiempo" DESC LIMIT 20;

-- Contar pagos por instancia (Ejercicio 8)
SELECT instancia, COUNT(*) as total 
FROM pago GROUP BY instancia ORDER BY instancia;

-- Borrar todos los pagos (antes de JMeter)
DELETE FROM pago;

-- Ver distribución temporal
SELECT instancia, "marcaTiempo" 
FROM pago ORDER BY "marcaTiempo" LIMIT 30;
```

Acceso a PostgreSQL en VM1:
```bash
sudo -u postgres psql -d si2
# o con credenciales:
psql -h localhost -U si2 -d si2
```
