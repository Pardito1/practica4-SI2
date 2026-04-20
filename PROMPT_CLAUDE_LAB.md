# Prompt para claude.ai en el lab

Copia y pega este bloque completo como primer mensaje en claude.ai:

---

Estoy haciendo la Práctica 4 de Sistemas Informáticos II (UAM). Es sobre balanceador de carga Apache con un clúster de 3 instancias Django. Necesito tu ayuda para ejecutar los 8 ejercicios en el lab.

## Arquitectura
- VM1: PostgreSQL + Apache balanceador (puerto 18080) + Django (puerto 18000)
- VM2: Django (puerto 28000)
- VM3: Django (puerto 38000)
- Balanceador Apache con mod_proxy_balancer, sticky sessions (cookie ROUTEID)
- SESSION_ENGINE = cache (LocMemCache) — sesiones NO compartidas entre instancias
- Acceso por SSH desde el PC del lab. NO puedo copiar/pegar en la consola de VirtualBox, todo por SSH/SCP.

## Lo que ya está preparado (en un repo clonado en el PC del lab)
- Código Django modificado: modelo Pago tiene campo `instancia`, vistas capturan `request.COOKIES.get('ROUTEID')`, templates lo muestran
- Config Apache (`scripts/000-default.conf`) lista, solo cambiar IPs
- Script setup (`scripts/setup_balancer_vm1.sh`) que añade Listen 18080, habilita módulos, reinicia Apache
- JMeter (`P4_P1-base.jmx`): 1 hilo, 1000 pagos, puerto 18080, csrfmiddlewaretoken como parámetro POST
- Borrador de memoria con texto teórico completo

## Addendum de los profesores
1. Apache reescribe URLs: `http://IP:18080/P1base/` → Django recibe `http://IP:18000/`. settings.py tiene `ALLOWED_HOSTS = ['*']`.
2. `csrfmiddlewaretoken` debe ir como parámetro POST (ya hecho en el JMX).

## Mis IPs (rellenar cuando las tenga)
- VM1: [RELLENAR]
- VM2: [RELLENAR]
- VM3: [RELLENAR]
- Usuario SSH: [RELLENAR]

## Plan paso a paso

### Setup:
1. Copiar código a las 3 VMs con `scp -r si2_alumnos-main/P1-base/ usuario@IP_VMx:~/P1-base/`
2. Copiar config Apache a VM1: `scp scripts/000-default.conf usuario@IP_VM1:/tmp/` y `scp scripts/setup_balancer_vm1.sh usuario@IP_VM1:/tmp/`
3. SSH a VM1: editar IPs en `/tmp/000-default.conf`, ejecutar `bash /tmp/setup_balancer_vm1.sh`
4. SSH a VM1: `cd ~/P1-base && python manage.py makemigrations visaApp && python manage.py migrate`
5. Arrancar Django en cada VM: `python manage.py runserver 0.0.0.0:PUERTO`
6. Verificar: `http://IP_VM1:18080/P1base/visaApp/tarjeta/`

### Ejercicios:
- **Ej1**: Capturas de systemctl, apachectl, balancer-manager
- **Ej2**: Apagar VM2/VM3, curl 3 veces, capturas balancer-manager, repetir con navegador
- **Ej3**: Deshabilitar 2 instancias en balancer-manager, pago, verificar BD
- **Ej4**: Quitar sticky session, provocar error (sesión+CSRF se pierden al cambiar instancia)
- **Ej5**: Apagar instancia con menos Elected, verificar redistribución
- **Ej6**: Reencender instancia, verificar failback
- **Ej7**: Pago a medio flujo, tumbar instancia, ver error CSRF/sesión
- **Ej8**: JMeter 1000 pagos, `SELECT instancia, COUNT(*) FROM pago GROUP BY instancia;`

## SQL útil
```sql
SELECT instancia, COUNT(*) FROM pago GROUP BY instancia ORDER BY instancia;
DELETE FROM pago;
```
PostgreSQL en VM1: `sudo -u postgres psql -d si2`

## Cómo quiero que me ayudes
Dame los comandos exactos copy-paste para cada paso. Cuando te pase un resultado o captura, dime qué responder en la memoria. Responde en español, sé directo.

Empecemos: ya tengo las VMs arrancadas. Las IPs son: VM1=X, VM2=Y, VM3=Z, usuario SSH=U. Dame los comandos del setup.

---
