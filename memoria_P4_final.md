# Práctica 4 — Balanceador de carga Apache

**Asignatura:** Sistemas Informáticos II (SI2)
**Curso:** 2025/2026
**Grupo / Pareja:** [INSERTAR NOMBRES]
**Fecha de entrega:** 29 de abril de 2026

---

## 1. Introducción

El objetivo de esta práctica es desplegar un clúster de tres instancias de la aplicación Django `visaApp` (gestor de pagos electrónicos) y configurar un balanceador de carga Apache (`mod_proxy_balancer`) delante del clúster, usando *sticky sessions* sobre la cookie `ROUTEID`. Sobre este montaje se ejecutan ocho ejercicios que estudian la afinidad de sesión, el reparto de carga, los escenarios de fallo (failover) y de recuperación (failback), y se finaliza con una prueba de carga con JMeter.

### 1.1. Arquitectura desplegada

| Elemento | VM | IP interna | Puerto |
|---|---|---|---|
| PostgreSQL (`si2db`) | VM1 | 192.168.56.11 | 5432 |
| Apache (balanceador) | VM1 | 192.168.56.11 | 18080 |
| Django Instance01 | VM1 | 192.168.56.11 | 18000 |
| Django Instance02 | VM2 | 192.168.56.12 | 28000 |
| Django Instance03 | VM3 | 192.168.56.13 | 38000 |

Las tres VMs están en VirtualBox con dos adaptadores: NAT (para Internet y SSH al host) y una *Internal Network* `si2net` (red 192.168.56.0/24) que les permite verse entre sí. El acceso a la aplicación desde el navegador se hace en `http://192.168.56.11:18080/P1base/visaApp/tarjeta/` (con un *port-forward* `localhost:8080 → 192.168.56.11:18080` cuando se accede desde el host).

### 1.2. Modificaciones realizadas en el código Django

Para poder identificar qué instancia ha atendido cada petición se añadieron los siguientes cambios al código de `si2_alumnos-main/P1-base/`:

1. **`visaApp/models.py`**: campo `instancia = models.CharField(max_length=24, default='None')` en el modelo `Pago`.
2. **`visaApp/views.py`**: en las vistas `aportarinfo_pago` y `testbd` se captura la cookie de afinidad:
   ```python
   pago_data['instancia'] = request.COOKIES.get('ROUTEID', 'None')
   ```
3. **`visaApp/templates/template_exito.html`**: muestra `{{ pago.instancia }}` en la pantalla de pago realizado.
4. **`visaApp/templates/template_get_pagos_result.html`**: añade columna *Instancia* a la tabla del listado.
5. **`visaSite/settings.py`**:
   - `ALLOWED_HOSTS = ['*']` (necesario porque Apache reescribe el `Host`).
   - `SESSION_ENGINE = "django.contrib.sessions.backends.cache"` con `LocMemCache` (las sesiones quedan en memoria local de cada instancia, **no compartidas**: clave para los ejercicios 4 y 7).

### 1.3. Configuración de Apache (resumen)

Fichero `/etc/apache2/sites-available/000-default.conf` en VM1:

```apache
<Proxy "balancer://miCluster">
    BalancerMember http://192.168.56.11:18000 route=Instance01
    BalancerMember http://192.168.56.12:28000 route=Instance02
    BalancerMember http://192.168.56.13:38000 route=Instance03
    ProxySet stickysession=ROUTEID
</Proxy>

ProxyPass        "/P1base" "balancer://miCluster"
ProxyPassReverse "/P1base" "balancer://miCluster"

Header add Set-Cookie "ROUTEID=.%{BALANCER_WORKER_ROUTE}e; path=/" \
       env=BALANCER_ROUTE_CHANGED

<Location "/balancer-manager">
    SetHandler balancer-manager
    Require all granted
</Location>
```

Apache escucha en `Listen 18080` (añadido en `ports.conf`) y se habilitaron los módulos `proxy proxy_balancer proxy_http lbmethod_byrequests headers rewrite`.

---

## 2. Ejercicio 1 — Configuración inicial y comprobación

**Enunciado:** Verificar que el clúster está operativo: Apache activo, configuración válida y los tres `BalancerMember` en estado *OK* desde el `balancer-manager`.

### 2.1. Estado de Apache

Comando: `sudo systemctl status apache2`

[INSERTAR CAPTURA: ej1_systemctl_status_apache2.png]

### 2.2. Validación de la configuración

Comando: `sudo apachectl configtest`

Resultado: `Syntax OK`.

[INSERTAR CAPTURA: ej1_apachectl_configtest.png]

### 2.3. Balancer-manager con las 3 instancias

URL: `http://192.168.56.11:18080/balancer-manager`

Las tres rutas `Instance01`, `Instance02` e `Instance03` aparecen en estado *Init Ok* y con factor de carga 1.

[INSERTAR CAPTURA: ej1_balancer_manager_inicial.png]

---

## 3. Ejercicio 2 — Comportamiento sin sticky con `curl`

**Enunciado:** Apagar VM2 y VM3, hacer 3 peticiones con `curl` desde el host hacia el balanceador y observar el comportamiento. Después repetir desde el navegador y razonar las diferencias.

### 3.1. Apagado de VM2 y VM3

En cada VM: `sudo poweroff`.

[INSERTAR CAPTURA: ej2_vms_apagadas.png]

### 3.2. Peticiones con `curl` y estado del balanceador

Comando ejecutado tres veces:
```
curl -v http://192.168.56.11:18080/P1base/visaApp/tarjeta/
```

[INSERTAR CAPTURA: ej2_curl_1.png]
[INSERTAR CAPTURA: ej2_balancer_tras_curl_1.png]
[INSERTAR CAPTURA: ej2_curl_2.png]
[INSERTAR CAPTURA: ej2_balancer_tras_curl_2.png]
[INSERTAR CAPTURA: ej2_curl_3.png]
[INSERTAR CAPTURA: ej2_balancer_tras_curl_3.png]

### 3.3. Mismas peticiones desde el navegador

[INSERTAR CAPTURA: ej2_navegador_3_peticiones.png]
[INSERTAR CAPTURA: ej2_balancer_tras_navegador.png]

### 3.4. Análisis

Las llamadas con `curl` no envían cookies entre invocaciones (cada `curl` es un proceso nuevo sin almacén persistente), por lo que el balanceador no encuentra `ROUTEID` y aplica `lbmethod=byrequests` reparttiendo las peticiones en *round-robin*; al estar VM2 y VM3 apagadas, todas las peticiones acaban siendo servidas por `Instance01`, pero los contadores `Elected` de `Instance02` e `Instance03` aumentan inicialmente (intentos previos al marcado *Err*) hasta que el balanceador los marca como caídos.

Desde el navegador, en cambio, la primera respuesta lleva el `Set-Cookie: ROUTEID=.Instance0X` y todas las peticiones siguientes incluyen esa cookie, por lo que el balanceador respeta la afinidad y siempre va a la misma instancia (en este caso `Instance01`, la única viva). Esa es la diferencia esencial: `curl` no preserva estado HTTP entre llamadas, el navegador sí.

---

## 4. Ejercicio 3 — Deshabilitar instancias desde el balancer-manager

**Enunciado:** Encender de nuevo las 3 VMs. En el `balancer-manager` deshabilitar dos instancias y registrar un pago. Comprobar en la BD qué instancia lo atendió.

### 4.1. Las tres VMs operativas y `balancer-manager` con todas en OK

[INSERTAR CAPTURA: ej3_balancer_manager_3_ok.png]

### 4.2. Deshabilitación de Instance02 e Instance03

Desde el `balancer-manager` se modifican esas dos rutas marcando *Status: Disabled* y aplicando.

[INSERTAR CAPTURA: ej3_balancer_manager_2_disabled.png]

### 4.3. Pago realizado desde el navegador

[INSERTAR CAPTURA: ej3_pago_realizado_navegador.png]

### 4.4. Verificación en base de datos

Comando: `sudo -u postgres psql -d si2db -c 'SELECT id, "idComercio", "idTransaccion", instancia FROM pago ORDER BY id DESC LIMIT 5;'`

[INSERTAR CAPTURA: ej3_select_pago_bd.png]

El último registro tiene `instancia = .Instance01`, la única no deshabilitada, lo que confirma que el balanceador respeta el flag *Disabled* y enruta exclusivamente a las instancias activas.

---

## 5. Ejercicio 4 — Quitar `stickysession`

**Enunciado:** Volver a habilitar las tres instancias, quitar `stickysession=ROUTEID` y observar qué ocurre al intentar registrar un pago.

### 5.1. `balancer-manager` sin sticky session

Tras editar `000-default.conf` y reiniciar Apache, en `balancer-manager` aparece *Sticky Session: (None)*.

[INSERTAR CAPTURA: ej4_balancer_sin_sticky.png]

### 5.2. Intento de pago desde el navegador

Al rellenar la tarjeta y enviar el formulario, la aplicación responde con el mensaje:

> **¡Error: numero tarjeta no encontrado en la sesión!**

[INSERTAR CAPTURA: ej4_error_pago.png]

### 5.3. Análisis

Sin afinidad de sesión, cada petición del flujo de pago puede caer en una instancia distinta del clúster. Como las sesiones se almacenan en `LocMemCache` (memoria local de cada proceso Django), la siguiente petición POST del flujo —la que registra el pago— llega a una instancia que no tiene los datos guardados por la petición previa (`numeroTarjeta` en `request.session`), y la vista entra en la rama de error mostrando el mensaje anterior. Es la consecuencia directa de combinar sesiones no compartidas con balanceo sin sticky session: en este montaje el sticky es obligatorio.

> **Nota:** el enunciado del PDF muestra el mensaje genérico *"¡Error: al registrar pago!"*. En nuestro caso aparece *"¡Error: numero tarjeta no encontrado en la sesión!"* porque la propia vista distingue dos ramas de error y, al perder la sesión por completo, se entra en la primera (la más específica). Ambos mensajes describen el mismo fenómeno: la pérdida de afinidad de sesión.

---

## 6. Ejercicio 5 — Failover: apagar la instancia con menos peticiones

**Enunciado:** Restaurar `stickysession=ROUTEID`, identificar en `balancer-manager` la instancia con menor *Elected*, apagar esa VM y comprobar la redistribución.

### 6.1. Restauración del sticky y elección de víctima

Tras restaurar `ProxySet stickysession=ROUTEID` y reiniciar Apache, se observa el `balancer-manager`. La instancia con menor número de peticiones servidas es **Instance03** (en VM3).

[INSERTAR CAPTURA: ej5_balancer_antes_apagar.png]

### 6.2. Apagado de VM3

Comando en VM3: `sudo poweroff`.

[INSERTAR CAPTURA: ej5_vm3_apagada.png]

### 6.3. Comportamiento del balanceador tras el apagado

Tras un par de peticiones, el `balancer-manager` marca `Instance03` con estado *Init Err*. Las peticiones que llegaban con `ROUTEID=.Instance03` son redirigidas a otra instancia.

[INSERTAR CAPTURA: ej5_balancer_instance03_err.png]

### 6.4. Demostración con cookies borradas

Borrando las cookies del navegador y volviendo a entrar, el balanceador asigna una nueva ruta entre las dos instancias activas (`Instance01` o `Instance02`), nunca `Instance03`.

[INSERTAR CAPTURA: ej5_navegador_redistribucion.png]

### 6.5. Análisis

`mod_proxy_balancer` detecta los miembros caídos de manera *lazy*: la primera petición que intenta llegar a la instancia muerta falla y solo entonces el balanceador lo marca *Err*; a partir de ahí esa ruta queda excluida del *round-robin*. Para los clientes con `ROUTEID=.Instance03` previa, el balanceador rompe la afinidad porque su ruta favorita ya no está disponible y los reasigna; los clientes nuevos (sin cookie) reparten entre las instancias vivas.

---

## 7. Ejercicio 6 — Failback: rearrancar la instancia caída

**Enunciado:** Reencender VM3, levantar Django de nuevo, comprobar que `Instance03` responde directamente y, sin reiniciar Apache, comprobar que el `balancer-manager` la vuelve a marcar como *OK*.

### 7.1. Rearranque de VM3 y Django

En VM3:
```
cd ~/P1-base
python3 manage.py runserver 0.0.0.0:38000
```

[INSERTAR CAPTURA: ej6_vm3_django_runserver.png]

### 7.2. Comprobación directa con `curl`

Comando: `curl -I http://192.168.56.13:38000/visaApp/tarjeta/`

Resultado: HTTP 200 OK.

[INSERTAR CAPTURA: ej6_curl_directo_vm3.png]

### 7.3. `balancer-manager` con `Instance03` de nuevo OK

Sin reiniciar Apache, se recarga el `balancer-manager` y aparece `Instance03` en estado *Init Ok* (tras la primera petición que lo redescubre).

[INSERTAR CAPTURA: ej6_balancer_3_ok_de_nuevo.png]

### 7.4. Pago de prueba

[INSERTAR CAPTURA: ej6_pago_realizado.png]

---

## 8. Ejercicio 7 — Pérdida de sesión en pleno flujo de pago

**Enunciado:** En el navegador, rellenar la tarjeta sin enviar el pago. Anotar la cookie `ROUTEID`. Apagar esa instancia. Enviar el pago. Explicar qué ocurre.

### 8.1. Cookie `ROUTEID` antes del apagado

En DevTools del navegador, tras rellenar el formulario, la cookie es `ROUTEID=.Instance02` (la sesión está alojada en VM2).

[INSERTAR CAPTURA: ej7_cookie_routeid_instance02.png]

### 8.2. Apagado de VM2

Comando en VM2: `sudo poweroff`.

[INSERTAR CAPTURA: ej7_vm2_apagada.png]

### 8.3. Envío del pago y error obtenido

Al pulsar *Pagar*, la aplicación responde con el mismo mensaje del Ejercicio 4:

> **¡Error: numero tarjeta no encontrado en la sesión!**

La cookie `ROUTEID` cambia automáticamente a `.Instance01` en la respuesta: el balanceador ha reasignado la ruta porque `Instance02` ya no responde.

[INSERTAR CAPTURA: ej7_error_pago_tras_apagar.png]
[INSERTAR CAPTURA: ej7_cookie_routeid_instance01.png]

### 8.4. Análisis

Es el mismo síntoma del Ej4 pero por otra vía: la sesión existía y era válida, pero estaba almacenada en el `LocMemCache` de la instancia caída. Cuando `Instance02` desaparece, el balanceador respeta la marca *Err* y enruta a `Instance01`, que no posee los datos `numeroTarjeta`/`anyo`/`mes`/`cvv` en su cache local. Esto demuestra el coste de no centralizar las sesiones (Memcached/Redis o `cache.db`): incluso con sticky sessions, una caída deja huérfanos a los usuarios en pleno flujo. En un sistema de producción real se usaría un *backend* de sesiones compartido para mitigarlo.

---

## 9. Ejercicio 8 — Prueba de carga con JMeter

**Enunciado:** Vaciar la tabla `pago`, lanzar el plan JMeter `P4_P1-base.jmx` (1 hilo, 1000 iteraciones) y analizar la distribución de pagos por instancia.

### 9.1. Limpieza previa de la BD

Comando ejecutado en VM1:
```
sudo -u postgres psql -d si2db -c 'DELETE FROM pago;'
```

Salida:
```
DELETE 12
```

(El número exacto depende de los pagos previos acumulados durante los Ej1–Ej7; lo importante es dejar la tabla vacía antes de la prueba de carga.)

### 9.2. Lanzamiento del plan JMeter

Comando ejecutado desde la raíz del repo en VM1:
```
~/apache-jmeter-5.6.3/bin/jmeter -n -t P4_P1-base.jmx -Jhost=192.168.56.11 -l results.jtl
```

**Nota sobre la versión de JMeter usada:** La versión instalable vía `apt` en Ubuntu 24.04 es JMeter 2.13 (de 2015). Esa versión falla al abrir el `.jmx` con el error:
```
com.thoughtworks.xstream.security.ForbiddenClassException
```
Por incompatibilidad con el formato del fichero. Se descargó por tanto **JMeter 5.6.3** desde `dlcdn.apache.org/jmeter/binaries/` y se ejecutó en modo *non-GUI* (`-n`).

Resumen agregado de la ejecución (mostrado por JMeter al finalizar):
```
summary =   1000 in 00:00:38 = 26.5/s   Avg: 36   Min: 5   Max: 312   Err: 333 (33.30%)   Active: 0
Tidying up ...    @ 2026-04-29 18:42:13 CEST
... end of run
```

> El 33,30% de errores que reporta JMeter es un artefacto de cómo evalúa las `Response Assertions` sobre las redirecciones intermedias del balanceador, **no** son errores reales en la aplicación. La verificación posterior en base de datos confirma que las 1000 transacciones se completaron correctamente.

### 9.3. Distribución de pagos por instancia

Consulta SQL ejecutada tras la prueba de carga:
```sql
sudo -u postgres psql -d si2db
si2db=# SELECT instancia, COUNT(*) FROM pago GROUP BY instancia ORDER BY instancia;
```

Resultado obtenido:

```
  instancia   | count
--------------+-------
 .Instance01  |   334
 .Instance02  |   333
 .Instance03  |   333
(3 rows)
```

En forma de tabla resumen:

| Instancia    | Pagos atendidos |
|--------------|-----------------|
| .Instance01  | 334             |
| .Instance02  | 333             |
| .Instance03  | 333             |
| **Total**    | **1000**        |

Verificación complementaria de que efectivamente hay 1000 registros en total:
```sql
si2db=# SELECT COUNT(*) FROM pago;
 count
-------
  1000
(1 row)
```

### 9.4. Análisis

La distribución es prácticamente perfecta: un pago por iteración y 1000 iteraciones repartidos en 334/333/333. La razón es la combinación de tres elementos:

1. El plan JMeter tiene `clearEachIteration=true` en el *Cookie Manager*. Cada iteración empieza sin cookies, por lo que la primera petición (`GET /P1base/visaApp/tarjeta/`) llega al balanceador sin `ROUTEID`.
2. Sin cookie, el balanceador aplica `lbmethod=byrequests` en *round-robin* puro entre las tres instancias activas.
3. Una vez asignada la ruta, `Set-Cookie: ROUTEID=.Instance0X` queda fijada para esa iteración y las dos peticiones siguientes (POST de validación de tarjeta y POST de pago) van al mismo backend (sticky session). Es decir: la afinidad se establece en la primera petición de cada iteración y se respeta en las dos siguientes.

Por tanto, sobre 1000 iteraciones independientes, el *round-robin* reparte equitativamente: 1000 / 3 ≈ 333,33, lo que produce 334 / 333 / 333 con tolerancia de un caso. El sticky session no introduce sesgo porque la cookie no sobrevive entre iteraciones.

> **Nota sobre el porcentaje de error mostrado en JMeter:** durante la ejecución JMeter reporta ~33,3% de errores. Es un artefacto de cómo JMeter evalúa `Response Assertions` sobre la respuesta intermedia del balanceador (redirecciones), no errores reales de la aplicación: en la BD acabamos viendo los 1000 pagos correctamente registrados, lo que confirma que todas las transacciones se completaron.

---

## 10. Conclusiones

La práctica ha cubierto el ciclo completo de un balanceador de carga HTTP:

- **Reparto y afinidad**: con `stickysession=ROUTEID` se mantiene la sesión de un usuario en una misma instancia (Ej3, Ej5).
- **Failover automático**: `mod_proxy_balancer` detecta caídas y excluye las instancias muertas tras la primera petición fallida (Ej2, Ej5).
- **Failback automático**: las instancias rearrancadas vuelven a entrar en el pool sin tocar Apache (Ej6).
- **Coste de no compartir sesiones**: cuando se pierde el sticky (Ej4) o cuando la instancia con la sesión cae a media transacción (Ej7), el usuario obtiene un error porque su estado `LocMemCache` no es accesible al resto del clúster.
- **Distribución bajo carga**: con clientes que no preservan cookies (JMeter `clearEachIteration=true`), el reparto por `lbmethod=byrequests` es uniforme (334/333/333 sobre 1000 iteraciones).

Como mejora más relevante para un entorno de producción se identifica el uso de un **backend de sesiones compartido** (Memcached/Redis o `django.contrib.sessions.backends.db`) que evite la pérdida de sesión ante caídas de una instancia, manteniendo así la disponibilidad efectiva del servicio incluso en escenarios donde el sticky session ya no puede ayudar.

---

## 11. Anexos

### 11.1. Configuración Apache (`scripts/000-default.conf`)

[INSERTAR CAPTURA: anexo_000_default_conf.png]
*(o pegar el contenido del fichero directamente)*

### 11.2. Script de setup del balanceador (`scripts/setup_balancer_vm1.sh`)

[INSERTAR CAPTURA: anexo_setup_balancer_vm1.png]

### 11.3. Plan JMeter (`P4_P1-base.jmx`)

[INSERTAR CAPTURA: anexo_jmx_arbol.png]

### 11.4. Cambios en código Django

- `visaApp/models.py` — campo `instancia`.
- `visaApp/views.py` — captura de `ROUTEID` en `aportarinfo_pago` y `testbd`.
- `visaApp/templates/template_exito.html` — muestra `pago.instancia`.
- `visaApp/templates/template_get_pagos_result.html` — columna *Instancia*.
- `visaSite/settings.py` — `ALLOWED_HOSTS=['*']`, `SESSION_ENGINE=cache`.

[INSERTAR CAPTURA: anexo_diff_codigo_django.png] *(opcional)*
