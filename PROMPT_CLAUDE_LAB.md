# Prompt para pegar en Claude (claude.ai) en el lab

Copia y pega este bloque completo como primer mensaje:

---

Estoy haciendo la Práctica 4 de Sistemas Informáticos II (UAM). Es sobre balanceador de carga Apache con un clúster de 3 instancias Django. Necesito tu ayuda para ejecutar los 8 ejercicios en el lab.

## Contexto

**Arquitectura:**
- VM1: PostgreSQL + Apache balanceador (puerto 18080) + Django/gunicorn (puerto 18000)
- VM2: Django/gunicorn (puerto 28000)
- VM3: Django/gunicorn (puerto 38000)
- Balanceador Apache con mod_proxy_balancer, sticky sessions (cookie ROUTEID)
- SESSION_ENGINE = cache (LocMemCache) — sesiones NO compartidas entre instancias

**Lo que ya está preparado:**
- Código Django modificado: modelo Pago tiene campo `instancia`, las vistas capturan `request.COOKIES.get('ROUTEID')`, templates lo muestran
- Config Apache (`scripts/000-default.conf`) lista, solo hay que cambiar IPs
- JMeter (`P4_P1-base.jmx`) adaptado: 1 hilo, 1000 pagos, puerto 18080, entrypoint P1base/visaApp
- Borrador de memoria (`memoria_P4_borrador.docx`) con texto teórico completo

**Pendiente (lo que necesito hacer ahora):**
1. Generar migración Django (`makemigrations` + `migrate`)
2. Configurar Apache con las IPs reales
3. Ejecutar ejercicios 1-8 tomando capturas
4. Rellenar la memoria con las capturas

## Mis IPs
- VM1: [RELLENAR]
- VM2: [RELLENAR]
- VM3: [RELLENAR]

## Ejercicios a completar

**Ej1**: Configurar balanceador, capturas de `systemctl status apache2`, `apachectl configtest`, y balancer-manager.

**Ej2**: Apagar VM2 y VM3, reiniciar Apache en VM1, hacer 3 curl y captura de balancer-manager entre cada uno. Luego repetir desde navegador y explicar diferencias.

**Ej3**: Deshabilitar 2 instancias en balancer-manager, registrar un pago, verificar en BD con `SELECT * FROM pago;`

**Ej4**: Suprimir sticky session en balancer-manager, hacer pagos hasta que falle, explicar por qué (sesión en LocMemCache no se comparte + CSRF invalido)

**Ej5**: Identificar instancia con menos "Elected" en balancer-manager, apagarla (`sudo poweroff`), verificar que el balanceador redirige a las restantes, demostrar borrando cookies.

**Ej6**: Reactivar la instancia, acceder directamente, verificar en balancer-manager, hacer pagos y ver distribución.

**Ej7**: Empezar pago en navegador, ver qué instancia procesa (cookie ROUTEID), apagar esa instancia, enviar pago, ver que falla (sesión + CSRF perdidos).

**Ej8**: Ejecutar JMeter con `P4_P1-base.jmx`, antes limpiar pagos con `DELETE FROM pago;` y limpiar datos de Apache en balancer-manager. Después: `SELECT instancia, COUNT(*) FROM pago GROUP BY instancia;` para ver distribución.

## Cómo quiero que me ayudes

Dame los comandos exactos copy-paste para cada paso. Cuando te pase una captura o un resultado, ayúdame a interpretar qué responder en la memoria. Responde siempre en español, sé directo.

Empecemos: dime los primeros comandos que necesito ejecutar para configurar las VMs.

---
