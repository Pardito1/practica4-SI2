# Plan de Trabajo - Práctica 4 SI2: Balanceador de Carga

## Resumen
Configurar un balanceador de carga Apache con clúster de 3 instancias Django, sticky sessions, failover/failback, y pruebas JMeter.

## Arquitectura
- **VM1**: PostgreSQL + Apache (balanceador) + instancia Django (puerto 18000)
- **VM2**: Instancia Django (puerto 28000) - clon de VM1
- **VM3**: Instancia Django (puerto 38000) - clon de VM1
- **Balanceador**: Apache mod_proxy_balancer en VM1, puerto 18080
- **BD compartida**: PostgreSQL en VM1, accesible desde las 3 VMs

## Entregables
1. `memoria.pdf` - Respuestas a ejercicios 1-8
2. Código fuente modificado de P1-base
3. Plan de pruebas JMeter adaptado

---

## Ejercicios y Estado

### Ejercicio 1 (aprobado) - Configurar balanceador Apache
- [ ] Revertir SESSION_ENGINE a `cache` en settings.py
- [ ] Configurar `/etc/apache2/sites-available/000-default.conf` en VM1
- [ ] Habilitar módulos: proxy, proxy_balancer, proxy_http, lbmethod_byrequests, headers, rewrite
- [ ] Reiniciar Apache y verificar con `apachectl configtest`
- [ ] Captura: `systemctl status apache2`
- [ ] Captura: `apachectl configtest`
- [ ] Captura: consola balancer-manager
**Entregable**: 3 capturas en la memoria

### Ejercicio 2 (0.5 pts) - Prueba failover con solo VM1
- [ ] Apagar VM2 y VM3 (`sudo poweroff`)
- [ ] Reiniciar Apache en VM1
- [ ] Captura 1: balancer-manager (estado inicial)
- [ ] curl a la app → Captura 2: balancer-manager (tras 1ª petición)
- [ ] Repetir curl 2 veces más → Capturas 3 y 4
- [ ] Comentar: ¿qué nodos ejecutan? ¿cuándo detecta nodos apagados?
- [ ] Repetir tras reiniciar Apache, pero desde navegador. ¿Diferencias? ¿Por qué?
**Entregable**: 4 capturas + comentarios + prueba navegador

### Ejercicio 3 - Modificar modelo Pago (requisito para Ej. 3-8)
- [ ] Añadir campo `instancia = models.CharField(max_length=24, default='None')` al modelo Pago
- [ ] `makemigrations` + `migrate`
- [ ] Modificar vista de pago: `pago_data['instancia'] = request.COOKIES.get('ROUTEID')`
- [ ] Modificar template `get_pagos`: añadir `pago.instancia` al bucle
**Entregable**: Código fuente modificado

### Ejercicio 3 (0.5 pts) - Probar pago por instancia
- [ ] Desde balancer-manager, forzar uso de una sola instancia (deshabilitar las otras 2)
- [ ] Registrar un pago y verificar éxito
- [ ] Consultar BD para confirmar persistencia
- [ ] Capturas: (1) balancer con 2 deshabilitadas, (2) pago exitoso, (3) consulta BD
**Entregable**: 3 capturas en memoria

### Ejercicio 4 (0.5 pts) - Sticky session y errores
- [ ] Suprimir sticky session en consola del balanceador
- [ ] Acceder a la app por URL del balanceador
- [ ] Realizar pagos hasta que falle por afinidad de sesión
- [ ] Explicar qué y cómo afecta ProxySet sticky session a los errores
**Entregable**: Explicación + capturas del error

### Ejercicio 5 (1.0 pts) - Failover: caída de instancia
- [ ] Identificar instancia con menos elecciones en balancer-manager
- [ ] `sudo poweroff` en esa instancia
- [ ] Hacer peticiones y verificar que el balanceador redirige a las restantes
- [ ] Captura: balancer-manager mostrando instancia errónea
- [ ] Demostrar borrando cookies que siempre va a instancia activa
**Entregable**: Descripción + capturas del experimento

### Ejercicio 6 (0.5 pts) - Failback: reactivación de instancia
- [ ] Reiniciar la instancia caída
- [ ] Acceder directamente a la instancia para verificar que funciona
- [ ] Verificar en balancer-manager que está reactivada
- [ ] Hacer pagos y verificar distribución entre todas las instancias
**Entregable**: Evidencias de reactivación + capturas

### Ejercicio 7 (0.5 pts) - Failover durante sesión activa
- [ ] Abrir navegador, empezar flujo de pago (rellenar tarjeta)
- [ ] En la pantalla de pago, observar qué instancia procesa
- [ ] Detener esa instancia
- [ ] Completar el pago y enviar
- [ ] Observar qué instancia procesa y razonar por qué falla/funciona
**Entregable**: Capturas + razonamiento sobre CSRF/sesión

### Ejercicio 8 (1.0 pts) - Pruebas JMeter con balanceador
- [ ] Adaptar P3_P1-base.jmx: IP del clúster, nueva URL (/P1base/), 1 hilo, 1000 iteraciones
- [ ] Desactivar thinktime
- [ ] Limpiar datos previos en Apache/BD
- [ ] Ejecutar prueba JMeter
- [ ] Consultar BD: distribución de pagos por instancia (ordenar por marcaTiempo)
- [ ] Deducir algoritmo de reparto (round-robin vs sticky vs mixto)
**Entregable**: Evidencias JMeter + análisis de distribución

---

## Cambios en código necesarios

### 1. visaApp/models.py
```python
# Añadir al modelo Pago:
instancia = models.CharField(max_length=24, default='None')
```

### 2. visaApp/views.py (función de pago)
```python
# En la función que registra el pago, añadir:
pago_data['instancia'] = request.COOKIES.get('ROUTEID')
```

### 3. Template get_pagos_result
```html
<!-- Añadir columna instancia al bucle de pagos -->
{{ pago.instancia }}
```

### 4. visaSite/settings.py
```python
# Mantener cache para esta práctica (el enunciado dice revertir a cache)
SESSION_ENGINE = "django.contrib.sessions.backends.cache"
```

### 5. Apache config (VM1)
```apache
# /etc/apache2/sites-available/000-default.conf
# Ver listado completo en essay_1.pdf pág. 9
```

---

## Puntuación total: 5.0 puntos
- Ej1: aprobado (requisito)
- Ej2: 0.5
- Ej3: 0.5
- Ej4: 0.5
- Ej5: 1.0
- Ej6: 0.5
- Ej7: 0.5
- Ej8: 1.0
