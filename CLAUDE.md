# Práctica 4 SI2 - Balanceador de Carga Apache

## Contexto
Práctica 4 de Sistemas Informáticos II (SI2) de la UAM. Consiste en configurar un clúster de 3 instancias Django con Apache como balanceador de carga, sticky sessions, y pruebas de failover/failback con JMeter.

Somos 2 personas. Todo el código ya está modificado y listo. Solo falta ejecutar en las VMs del lab.

## Arquitectura
- **VM1**: PostgreSQL + Apache (balanceador en puerto 18080) + Django (puerto 18000)
- **VM2**: Django (puerto 28000) - clon de VM1
- **VM3**: Django (puerto 38000) - clon de VM1
- **BD compartida**: PostgreSQL en VM1, accesible desde las 3 VMs
- **Balanceador**: Apache mod_proxy_balancer con sticky sessions (cookie ROUTEID)
- **URL de la app**: http://IP_VM1:18080/P1base/visaApp/

## IMPORTANTE - Addendum de los profesores
1. Apache reescribe las URLs: aunque el cliente pide `http://IP:18080/P1base/`, a Django le llega `http://IP:18000/`. Por eso en settings.py se usa `ALLOWED_HOSTS = ['*']`.
2. En JMeter, el `csrfmiddlewaretoken` debe enviarse como **parámetro POST del formulario** (ya está hecho en el JMX).

## Acceso a las VMs
- Se accede por SSH desde el PC del lab: `ssh usuario@IP_VMx`
- Las VMs corren en VirtualBox
- NO se puede copiar/pegar desde el PC a la consola de VirtualBox. TODO se hace por SSH y SCP.

## Código Django (si2_alumnos-main/P1-base/)
App de pago electrónico (visaApp). Cambios ya realizados:
1. **models.py**: Campo `instancia = models.CharField(max_length=24, default='None')` en modelo Pago
2. **views.py**: `pago_data['instancia'] = request.COOKIES.get('ROUTEID', 'None')` en `aportarinfo_pago` y `testbd`
3. **template_exito.html**: Muestra `{{ pago.instancia }}`
4. **template_get_pagos_result.html**: Columna Instancia en la tabla
5. **settings.py**: `SESSION_ENGINE = "django.contrib.sessions.backends.cache"` (LocMemCache, sesiones NO compartidas)

## Migraciones PENDIENTES
Solo en VM1 (tiene PostgreSQL):
```bash
cd ~/P1-base
python manage.py makemigrations visaApp
python manage.py migrate
```

## Ficheros del repo
- `scripts/000-default.conf` — Config Apache (cambiar IPs antes de copiar a VM1)
- `scripts/setup_balancer_vm1.sh` — Script setup Apache en VM1 (añade Listen 18080, habilita módulos, reinicia)
- `P4_P1-base.jmx` — Plan JMeter: 1 hilo, 1000 iteraciones, puerto 18080, sin think times
- `memoria_P4_borrador.docx` — Borrador memoria con texto teórico y [TODO] para capturas
- `INSTRUCCIONES_LAB.md` — Pasos detallados
- `PLAN_PRACTICA4.md` — Plan de los 8 ejercicios con checklist

## Plan de ejecución paso a paso

### Fase 1: Setup (hacer ANTES de los ejercicios)

**1. Averiguar IPs** — En consola VirtualBox de cada VM: `hostname -I`

**2. Copiar código a las 3 VMs** (desde el PC del lab):
```bash
scp -r si2_alumnos-main/P1-base/ usuario@IP_VM1:~/P1-base/
scp -r si2_alumnos-main/P1-base/ usuario@IP_VM2:~/P1-base/
scp -r si2_alumnos-main/P1-base/ usuario@IP_VM3:~/P1-base/
```

**3. Copiar config Apache a VM1**:
```bash
scp scripts/000-default.conf usuario@IP_VM1:/tmp/
scp scripts/setup_balancer_vm1.sh usuario@IP_VM1:/tmp/
```

**4. En VM1 por SSH — editar IPs en config Apache**:
```bash
ssh usuario@IP_VM1
nano /tmp/000-default.conf
# Cambiar las 3 líneas "ip_address" por las IPs reales de VM1, VM2, VM3:
#   BalancerMember http://IP_VM1:18000 route=Instance01
#   BalancerMember http://IP_VM2:28000 route=Instance02
#   BalancerMember http://IP_VM3:38000 route=Instance03
# Cambiar XX.YY.ZZ.II por IP_VM1
```

**5. En VM1 — ejecutar setup Apache**:
```bash
bash /tmp/setup_balancer_vm1.sh
```

**6. En VM1 — migraciones Django**:
```bash
cd ~/P1-base
python manage.py makemigrations visaApp
python manage.py migrate
```

**7. Arrancar Django en las 3 VMs** (cada una en su SSH):
```bash
# VM1: python manage.py runserver 0.0.0.0:18000
# VM2: python manage.py runserver 0.0.0.0:28000
# VM3: python manage.py runserver 0.0.0.0:38000
```

**8. Verificar**: Desde navegador del PC: `http://IP_VM1:18080/P1base/visaApp/tarjeta/`

### Fase 2: Ejercicios

**Ej1 (aprobado)**: Capturas de `systemctl status apache2`, `apachectl configtest`, y `http://IP_VM1:18080/balancer-manager`

**Ej2 (0.5 pts)**: Apagar VM2 y VM3 (`sudo poweroff`). Reiniciar Apache. Hacer 3 curl y captura de balancer-manager entre cada uno. Luego repetir desde navegador. Explicar diferencias (curl no manda cookies → round-robin, navegador sí → sticky).

**Ej3 (0.5 pts)**: En balancer-manager, deshabilitar 2 instancias. Registrar un pago. Verificar en BD: `SELECT * FROM pago ORDER BY id DESC LIMIT 5;`

**Ej4 (0.5 pts)**: En balancer-manager, quitar sticky session. Hacer pagos. Falla porque: sin sticky, cada petición puede ir a distinta instancia → sesión LocMemCache se pierde → CSRF token no coincide.

**Ej5 (1.0 pts)**: Ver qué instancia tiene menos "Elected" en balancer-manager. Apagarla (`sudo poweroff`). Hacer peticiones, ver redistribución. Borrar cookies para demostrar que solo va a instancias activas.

**Ej6 (0.5 pts)**: Reencender la instancia. Verificar directamente (`curl http://IP_VMx:puerto/visaApp/tarjeta/`). Ver en balancer-manager que reaparece. Hacer pagos.

**Ej7 (0.5 pts)**: En navegador, rellenar tarjeta. Ver cookie ROUTEID (qué instancia). Apagar esa instancia. Enviar pago. Falla: el balanceador redirige a otra instancia, pero esa no tiene la sesión ni el CSRF token → error 403.

**Ej8 (1.0 pts)**: Limpiar BD (`DELETE FROM pago;`). Ejecutar JMeter: `jmeter -n -t P4_P1-base.jmx -Jhost=IP_VM1 -l results.jtl`. Después: `SELECT instancia, COUNT(*) FROM pago GROUP BY instancia ORDER BY instancia;`. Analizar: primer pago de cada iteración es round-robin (sin cookie), los 2 siguientes son sticky → distribución ~333 por instancia.

## Consultas SQL útiles
```sql
SELECT id, "idComercio", "idTransaccion", instancia, "marcaTiempo" FROM pago ORDER BY "marcaTiempo" DESC LIMIT 20;
SELECT instancia, COUNT(*) as total FROM pago GROUP BY instancia ORDER BY instancia;
DELETE FROM pago;
```

Acceso PostgreSQL en VM1: `sudo -u postgres psql -d si2`

## Config JMeter
- Host: variable `${host}` → pasar con `-Jhost=IP_VM1`
- Puerto: 18080 (hardcoded)
- Entrypoint: P1base/visaApp
- 1 hilo, 1000 iteraciones
- Cookie Manager con clearEachIteration=true (correcto: cada iteración empieza sin cookies → round-robin)
- CSV: `si2_alumnos-main/P1-base/visaApp/management/commands/data.csv` (lanzar JMeter desde la carpeta del repo)

## Preferencias
- Responde en español
- Sé directo y conciso
- Para la memoria: español formal/académico
- Para comandos: copy-paste ready
