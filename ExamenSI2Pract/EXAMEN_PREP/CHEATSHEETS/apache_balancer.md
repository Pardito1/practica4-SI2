# Cheatsheet — Apache balanceador (P3/P4)

> En el examen las preguntas sobre el balanceador suelen ser **conceptuales** (sticky session, cookies) o **diagnóstico** (¿por qué falla un pago?). Rara vez piden montar el cluster desde cero — pero si lo piden, también está aquí.

## Conceptos clave

### Sticky Session

- **Sin sticky**: el balanceador reparte cada petición independientemente (round-robin). Para una app con sesión local (LocMemCache de Django), eso rompe el flujo: la petición de validar tarjeta va a Instance01 y la de hacer el pago va a Instance02 → la sesión está en Instance01 → error "numero tarjeta no encontrado en sesión".
- **Con sticky**: el balanceador identifica al cliente con una cookie (`ROUTEID` en mod_proxy_balancer; `JSESSIONID` en mod_jk de tomcat) y lo enruta siempre a la misma instancia. La sesión persiste.

### Cookies del balanceador

| Tecnología | Cookie | Formato |
|---|---|---|
| Apache mod_proxy_balancer (Django) | `ROUTEID` | `.Instance01`, `.Instance02`... (con punto delante) |
| Apache mod_jk (Tomcat) | `JSESSIONID` | `<id>.Instance01` (sufijo separado por punto) |

**Pregunta típica del examen:** "Si vemos esta cookie ¿es posible? ¿por qué?"

- `JSESSIONID = be1afff1f7615a6a33b70e584d42` → **posible solo si NO hay sticky configurado** (Tomcat puro).
- `JSESSIONID = be1afff1f7615a6a33b70e584d42.Instance01` → **posible si sticky está configurado** y el balanceador añade el sufijo de la ruta. Es lo "normal" cuando todo funciona.

Si el examen pregunta cuál es posible bajo la configuración descrita, mira si el balanceador tiene sticky o no.

### Failover / failback en mod_proxy_balancer

- **Failover (lazy detection)**: cuando una instancia muere, el balanceador NO se entera hasta que la primera petición intenta llegar a ella. En ese momento, marca el `BalancerMember` como `Init Err` y reasigna la petición a otra instancia.
- **Failback automático**: cuando la instancia vuelve a estar disponible, el balanceador la marca `Init Ok` en cuanto la primera petición de prueba lo descubre. **No requiere reiniciar Apache**.

## Diagnóstico típico (Ejercicio 3 examen 22-23 y 2024 mañana)

**Escenario**: cluster con 2 instancias, P3 desplegada, formulario de pago/voto, todo bien configurado, BD vacía. Se rellena el formulario, se pulsa enviar, devuelve "pago/voto incorrecto". Estado del balanceador antes y después.

**Causas posibles a justificar:**

1. **Sticky session NO configurada**: las peticiones del flujo de pago se reparten round-robin entre las 2 instancias. La que recibe el POST final no tiene la `numeroTarjeta` en `request.session` porque esa sesión vive en LocMemCache de la otra. → "pago incorrecto".

2. **Las dos instancias no comparten BD**: cada Django apunta a su BD local. La tarjeta se da de alta en una BD pero la otra no la conoce.

3. **Las dos instancias no comparten media/static**: Django no encuentra ficheros estáticos.

4. **Discrepancia de migraciones**: una instancia tiene la BD actualizada, la otra no.

**Acciones para corregir:**

1. Habilitar sticky session: `ProxySet stickysession=ROUTEID` en el `<Proxy "balancer://...">`.
2. Configurar `Header add Set-Cookie "ROUTEID=.%{BALANCER_WORKER_ROUTE}e; path=/" env=BALANCER_ROUTE_CHANGED` para que se establezca la cookie.
3. Reiniciar Apache: `sudo systemctl restart apache2`.
4. Borrar las cookies del navegador y reintentar.

## Configuración Apache (referencia)

Fichero `/etc/apache2/sites-available/000-default.conf`:

```apache
<VirtualHost *:18080>
    ServerName 192.168.56.11
    ProxyRequests Off
    ProxyPreserveHost On

    <Proxy "balancer://miCluster">
        BalancerMember http://192.168.56.11:18000 route=Instance01
        BalancerMember http://192.168.56.12:28000 route=Instance02
        BalancerMember http://192.168.56.13:38000 route=Instance03
        ProxySet stickysession=ROUTEID
        ProxySet lbmethod=byrequests
    </Proxy>

    ProxyPass        "/P1base" "balancer://miCluster"
    ProxyPassReverse "/P1base" "balancer://miCluster"

    Header add Set-Cookie "ROUTEID=.%{BALANCER_WORKER_ROUTE}e; path=/" \
        env=BALANCER_ROUTE_CHANGED

    <Location "/balancer-manager">
        SetHandler balancer-manager
        Require all granted
    </Location>

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
```

Y en `/etc/apache2/ports.conf`:
```
Listen 18080
```

Módulos:
```bash
sudo a2enmod proxy proxy_balancer proxy_http lbmethod_byrequests headers rewrite
sudo systemctl restart apache2
```

## Comandos útiles

### Verificar estado del balanceador
```bash
# En navegador del HOST:
http://localhost:18080/balancer-manager

# O por curl:
[VM] curl -s http://127.0.0.1:18080/balancer-manager | grep -E 'Instance|Status'
```

### Reiniciar Apache (después de cambios en config)
```bash
[VM] sudo apachectl configtest    # verificar sintaxis primero
[VM] sudo systemctl restart apache2
```

### Ver logs
```bash
[VM] sudo tail -f /var/log/apache2/error.log
[VM] sudo tail -f /var/log/apache2/access.log
```

### Habilitar / deshabilitar sitios
```bash
[VM] sudo a2ensite mi_sitio
[VM] sudo a2dissite mi_sitio
[VM] sudo systemctl reload apache2
```

## Preguntas de Ej3 examen 2024 tarde (teóricas)

### a) `ssh-keygen` para conectarse sin password al cluster

**Suposición**: 3 VMs (`si2srv01`, `si2srv02`, `si2srv03`). DAS en si2srv01, nodos de trabajo en si2srv02 y si2srv03.

**Comandos**:
```bash
# En si2srv01 (DAS):
ssh-keygen -t rsa            # generar par de claves (si no existe ya)
                             # (acepta defaults, deja passphrase vacío)
ssh-copy-id usuario@si2srv02
ssh-copy-id usuario@si2srv03
```

`ssh-copy-id` copia la **clave pública** del DAS a `~/.ssh/authorized_keys` de cada nodo. A partir de ese momento, `ssh usuario@si2srv02` desde si2srv01 entra sin pedir password.

> Si el ssh-copy-id no está disponible, equivalente manual:
> ```bash
> cat ~/.ssh/id_rsa.pub | ssh usuario@si2srv02 'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys'
> ```

### b) `si2fixMAC.sh`

Script que, antes de arrancar las VMs en VirtualBox, **regenera las MAC addresses** de cada interfaz de red para que sean únicas. En VirtualBox, al clonar una VM, las MAC se quedan iguales y eso puede dar conflictos en la red interna del cluster (varias VMs compitiendo por el mismo IP).

Sirve para que las 3 VMs del cluster tengan MACs distintas tras un clonado.

### c) `virtualip.sh` y diferencia con `si2fixMAC.sh`

`virtualip.sh` configura una **IP virtual / IP flotante** en una de las VMs (típicamente la del DAS o la del balanceador) para que el cluster tenga una IP única de entrada que pueda migrar entre máquinas si una cae (HA — high availability).

**Diferencia**:
- `si2fixMAC.sh` opera a nivel **MAC** (capa 2) — cada VM tiene su propia MAC única.
- `virtualip.sh` opera a nivel **IP** (capa 3) — el cluster tiene una IP de servicio compartida que se asigna a la VM activa.

## Si el examen pide MONTAR el balanceador

Esto sería excepcional, pero si pasa:

1. Edita `/etc/apache2/sites-available/000-default.conf` con la config arriba.
2. Edita `/etc/apache2/ports.conf` añadiendo `Listen 18080`.
3. Habilita módulos: `sudo a2enmod proxy proxy_balancer proxy_http lbmethod_byrequests headers rewrite`.
4. `sudo apachectl configtest`.
5. `sudo systemctl restart apache2`.
6. Prueba: `curl -sI http://localhost:18080/balancer-manager`.

Pero seguramente el examen pedirá **diagnosticar** o **modificar** la config existente, no montarla desde cero.
