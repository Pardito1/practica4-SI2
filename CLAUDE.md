# Práctica 4 SI2 - Balanceador de Carga Apache

## Contexto
Práctica 4 de Sistemas Informáticos II (SI2) de la UAM. Consiste en configurar un clúster de 3 instancias Django con Apache como balanceador de carga, sticky sessions, y pruebas de failover/failback con JMeter.

## Arquitectura
- **VM1**: PostgreSQL + Apache (balanceador en puerto 18080) + Django/gunicorn (puerto 18000)
- **VM2**: Django/gunicorn (puerto 28000) - clon de VM1
- **VM3**: Django/gunicorn (puerto 38000) - clon de VM1
- **BD compartida**: PostgreSQL en VM1, accesible desde las 3 VMs
- **Balanceador**: Apache mod_proxy_balancer con sticky sessions (cookie ROUTEID)
- **URL de la app a través del balanceador**: http://IP_VM1:18080/P1base/visaApp/

## Acceso a las VMs
- Se accede por SSH desde el PC del lab
- Las VMs corren en VirtualBox en los PCs del lab

## Código Django (si2_alumnos-main/P1-base/)
App de pago electrónico (visaApp) con:
- Modelo `Pago` con campo `instancia` (CharField, max_length=24) para rastrear qué instancia del clúster procesa cada pago
- Vista `aportarinfo_pago` que captura `request.COOKIES.get('ROUTEID')` y lo guarda en el pago
- Template `template_get_pagos_result.html` que muestra la instancia en el listado
- SESSION_ENGINE = cache (LocMemCache) — sesiones NO compartidas entre instancias (esto es intencional, es lo que pide el enunciado)

## Cambios ya realizados respecto a P1-base original
1. **models.py**: Añadido `instancia = models.CharField(max_length=24, default='None')` al modelo Pago
2. **views.py**: Añadido `pago_data['instancia'] = request.COOKIES.get('ROUTEID', 'None')` en `aportarinfo_pago` y `testbd`
3. **template_exito.html**: Muestra `{{ pago.instancia }}`
4. **template_get_pagos_result.html**: Añadida columna Instancia en la tabla

## Migraciones PENDIENTES
El campo `instancia` está en models.py pero NO se ha generado la migración. Hay que ejecutar en cada VM:
```bash
cd /path/to/P1-base
python manage.py makemigrations visaApp
python manage.py migrate
```

## Ficheros importantes
- `scripts/000-default.conf` — Config Apache para el balanceador (cambiar IPs antes de copiar)
- `scripts/setup_balancer_vm1.sh` — Script de setup rápido para VM1
- `scripts/setup_django_p4.sh` — Script para aplicar migraciones
- `P4_P1-base.jmx` — Plan JMeter: 1 hilo, 1000 pagos, puerto 18080, sin think times
- `memoria_P4_borrador.docx` — Borrador de la memoria con texto teórico completo y [TODO] para capturas
- `PLAN_PRACTICA4.md` — Plan detallado de los 8 ejercicios

## Ejercicios (8 ejercicios, 5 puntos total)
- **Ej1** (aprobado): Configurar balanceador + capturas (systemctl status, apachectl configtest, balancer-manager)
- **Ej2** (0.5): Solo VM1 activa, 4 capturas de balancer-manager, comparar curl vs navegador
- **Ej3** (0.5): Registrar pago en una instancia, verificar en BD
- **Ej4** (0.5): Suprimir sticky session, provocar error, explicar por qué falla
- **Ej5** (1.0): Failover: apagar instancia, verificar redistribución
- **Ej6** (0.5): Failback: reactivar instancia, verificar reintegración
- **Ej7** (0.5): Failover durante sesión activa, explicar por qué falla (CSRF + sesión perdida)
- **Ej8** (1.0): JMeter 1000 pagos, analizar distribución por instancia, deducir algoritmo

## Configuración JMeter (P4_P1-base.jmx)
- Host: `${host}` (variable, cambiar a IP del clúster)
- Puerto: 18080
- Entrypoint: P1base/visaApp
- 1 hilo, 1000 iteraciones, timers desactivados
- Cookie Manager con clearEachIteration=true (correcto: cada iteración empieza round-robin, sticky session dentro de la iteración)
- CSV: `si2_alumnos-main/P1-base/visaApp/management/commands/data.csv` (ruta relativa, lanzar JMeter desde la carpeta correcta)

## Preferencias
- Responde en español
- Sé directo y conciso
- Para la memoria: español formal/académico
- Para comandos: copy-paste ready
