# Examen SI2 22-23 — Análisis y solución razonada

> Origen: `wuolah-free-SI2-practicas-22-23.pdf`. Páginas 1-3 visibles (no tenemos 4-6 completos).

## Datos formales

- **Duración**: 2 horas.
- **Entrega**: archivo `.tar.gz` con nombre `SI2EXTxPyyApellido1Apellido2Nombre.tar.gz` (x=turno, yy=pareja).
- **Contenido del .tar.gz**: subdirectorio con el mismo nombre, conteniendo:
  - `Ejercicio1.txt`
  - `Ejercicio2.txt`
  - `P2.jmx` (modificado en Ej2)
  - `Ejercicio3.txt`
  - Carpeta `P1-base-ex` (modificada en Ej1)
- **Puntuación**: 3 ejercicios × 10 puntos. Nota = promedio.

## Ejercicio 1 — Modificar P1-base con campo "concepto"

### Lo que pedía
1. Copiar `P1-base` a `P1-base-ex`.
2. Modificar `build.properties` para nombre `P1-base-ex` (en Django: ignorable, renombrar carpeta basta).
3. Hacer cambios para una sola VM (no cluster).
4. Añadir campo `concepto` (max 30 chars) a `pago`:
   - HTML que da el enunciado:
     ```html
     <tr>
       <td>Concepto: </td>
       <td><input type="text" name="Concepto" maxlength="30" size="20" /></td>
     </tr>
     ```
   - SQL: `alter table pago add column concepto char(30) not null;`
   - PagoBean: variable + getter/setter.
   - Servlets `ComienzaPago` y `ProcesaPago` para actualizar el objeto Pago. **OJO**: `ProcesaPago` solo añade el concepto si NO hay objeto pago en sesión (es decir, si la petición viene de testbd.jsp).
   - VisaDAO: insertar pago con concepto (queries preparadas y no preparadas).
5. Probar con pago.html y testbd.jsp.
6. Adjuntar `SELECT * FROM PAGO;` en `Ejercicio1.txt`.

### Solución (en Django)

#### 1. Copia
```bash
cp -r ExamenSI2Pract/SI2P1_2311_AlejandroPablo/SI2-P1-entrega/P1-base ./P1-base-ex
```

#### 2. `models.py` — añadir campo `concepto`

```python
# visaApp/models.py
class Pago(models.Model):
    idComercio = models.CharField(max_length=16)
    idTransaccion = models.CharField(max_length=16)
    importe = models.FloatField()
    tarjeta = models.ForeignKey(Tarjeta, on_delete=models.CASCADE)
    marcaTiempo = models.DateTimeField(auto_now=True)
    codigoRespuesta = models.CharField(max_length=3,
                                       default=CodigoRespuesta.RESPUESTA_OK)
    Concepto = models.CharField(max_length=30, default='', blank=True)   # NUEVO

    class Meta:
        constraints = [UniqueConstraint(fields=['idTransaccion', 'idComercio'],
                                        name='unique_blocking_pago')]
        db_table = 'pago'
```

> ⚠️ El nombre del campo es **`Concepto`** (con C mayúscula) porque el HTML tiene `name="Concepto"`.

#### 3. `forms.py` — añadir al PagoForm

```python
class PagoForm(forms.Form):
    idComercio = forms.CharField(label='ID Comercio', required=True)
    idTransaccion = forms.CharField(label='ID Transaccion', required=True)
    importe = forms.FloatField(label='Importe', required=True)
    Concepto = forms.CharField(label='Concepto', max_length=30, required=True)   # NUEVO
```

#### 4. Templates — añadir HTML literal del enunciado

`template_pago.html` y `template_test_bd.html`:

```html
<form method="post">
    {% csrf_token %}
    <table>
        {{ form.idComercio.label_tag }} {{ form.idComercio }}
        {{ form.idTransaccion.label_tag }} {{ form.idTransaccion }}
        {{ form.importe.label_tag }} {{ form.importe }}
        <tr>
            <td>Concepto: </td>
            <td><input type="text" name="Concepto" maxlength="30" size="20"></td>
        </tr>
    </table>
    <button type="submit">Enviar Información Pago</button>
</form>
```

#### 5. `pagoDB.py` — Django ORM ya soporta el campo automáticamente

`Pago.objects.create(**pago_dict)` ya recoge `Concepto` si está en el dict (que viene de `pago_form.cleaned_data`). **No hace falta tocar nada**.

Si el examen exige queries no preparadas explícitas, añadir versión raw:
```python
def registrar_pago_raw(pago_dict):
    from django.db import connection
    sql = ("INSERT INTO pago (idComercio, idTransaccion, importe, "
           "tarjeta_id, marcaTiempo, codigoRespuesta, \"Concepto\") "
           "VALUES (%s, %s, %s, %s, NOW(), '000', %s)")
    with connection.cursor() as c:
        c.execute(sql, [pago_dict['idComercio'], pago_dict['idTransaccion'],
                        pago_dict['importe'], pago_dict['tarjeta_id'],
                        pago_dict['Concepto']])
```

#### 6. Migración

```bash
[VM] cd ~/P1-base-ex && source ~/venv/bin/activate
[VM] python manage.py makemigrations visaApp
[VM] python manage.py migrate
```

#### 7. Probar

Navegador del HOST: `http://localhost:18000/visaApp/tarjeta/`
- Rellenar tarjeta → continuar a pago → rellenar pago + concepto → enviar.
- Repetir 3-4 veces con conceptos distintos.

#### 8. SELECT en Ejercicio1.txt

```bash
[VM] sudo -u postgres psql -d si2db -c 'SELECT * FROM pago;'
```

Pegar la salida completa.

---

## Ejercicio 2 — JMeter: 20 usuarios × 225 pagos

### Lo que pedía
- 20 usuarios × 225 pagos cada uno = **4500 pagos** sobre P1-base.
- Importe aleatorio entre 150 y 500 €.
- ID transacción empezar en 125, incrementar de 1 en 1.
- ID comercio: siempre 173.
- Describir pasos en `Ejercicio2.txt` y entregar `P2.jmx` modificado.

### Solución

#### 1. Abrir el JMX

```bash
[HOST] ~/apache-jmeter-5.6.3/bin/jmeter \
       -t ExamenSI2Pract/SI2P3_2311_Parte1/P3_P1-base.jmx
```

#### 2. Thread Group

- Number of Threads: **20**
- Loop Count: **225**
- Ramp-up Period: 10 seg (suave)

#### 3. Counter "idTransaccion"

```
Add → Config Element → Counter
  Start: 125
  Increment: 1
  Reference Name: idTrans
  Per User: false  (compartido)
```

#### 4. Random importe

En el body POST del HTTP Request, sustituir:
- `importe` → `${__Random(150,500,importe)}`

#### 5. ID comercio fijo

En el body POST:
- `idComercio` → `173` (literal)

#### 6. ID transacción

En el body POST:
- `idTransaccion` → `${idTrans}`

#### 7. Cookie Manager

Comprobar: `Clear Cookies each Iteration: ✓` (necesario en cluster, irrelevante en single VM, pero no estorba).

#### 8. Lanzar

```bash
[HOST] ~/apache-jmeter-5.6.3/bin/jmeter -n -t P2.jmx \
       -Jhost=localhost -Jport=18000 -l results.jtl
```

#### 9. Verificar

```bash
[VM] sudo -u postgres psql -d si2db -c 'SELECT COUNT(*) FROM pago;'
# Esperado: ~4500 (puede haber colisiones de unique constraint si combinaciones se repiten,
# pero con 20 hilos y idTrans incremental compartido NO debería haber duplicados)
```

#### 10. Ejercicio2.txt

Ver plantilla. Documentar:
- Hilos = 20, loops = 225 → 4500 esperados.
- Counter idTrans 125 +1 paso, compartido.
- ${__Random(150,500,importe)}.
- idComercio = "173" literal.
- Resultado del summary y del COUNT(*).

---

## Ejercicio 3 — Cluster con 2 instancias, voto incorrecto

### Lo que pedía

En la P3 se desplegó P3 en SI2Cluster con 2 instancias. Se prueba un pago en `pago.html`:
- Estado balancer-manager **ANTES** de pulsar enviar: muestra contadores Elected, From, etc.
- Se rellena formulario, se pulsa Pagar.
- Resultado: "pago incorrecto".
- Estado balancer-manager **DESPUÉS**: contadores incrementados, pero pago fallido.

Preguntas:
1. Justificar fallo del pago (todo bien configurado, P3 desplegada, datos correctos, BD vacía).
2. Cookie JSESSIONID: ¿valor `be1afff1f7615a6a33b70e584d42` o `be1afff1f7615a6a33b70e584d42.Instance01` posible? Razonar.
3. Acciones para corregir el error.

### Solución razonada

#### Pregunta 1 — Por qué falla

**El balancer-manager mostraba sticky session = `JSESSIONID jsessionid` y método = byrequests, pero el sticky NO está aplicándose efectivamente para el flujo POST**. Causas más probables:

1. **Las cookies del navegador estaban vacías o el Set-Cookie no se está enviando con el formato correcto** (sin sufijo `.Instance01` que distingue ruta). Sin sticky efectivo, los 3 pasos del pago (validar tarjeta, mostrar pago, registrar pago) caen en instancias distintas. Como Django usa LocMemCache, la `numeroTarjeta` guardada en `request.session` por la instancia 01 no la encuentra la instancia 02 cuando llega el POST final.

2. **Posible mismatch en `route` de los BalancerMember vs el sufijo añadido en el `Header add Set-Cookie`**: si la directiva `JvmRoute` o `route=` no coincide con el sufijo que se inyecta, el balanceador no respeta la afinidad.

#### Pregunta 2 — Cookies posibles

- `JSESSIONID = be1afff1f7615a6a33b70e584d42` — **POSIBLE solo si NO hay sticky session activa**. Es el formato puro de Tomcat/Django sin balanceador o con balanceador sin afinidad.
- `JSESSIONID = be1afff1f7615a6a33b70e584d42.Instance01` — **POSIBLE cuando sticky session SÍ está activo** y el balanceador inyecta el sufijo de ruta. Bajo la configuración del enunciado (que tiene sticky configurado en balancer-manager), es el valor esperado/correcto.

Si el alumno ve la cookie SIN sufijo en este escenario, indica que el sticky NO está funcionando aunque el balancer-manager lo declare → eso es la causa raíz del fallo en pregunta 1.

#### Pregunta 3 — Cómo corregir

1. Editar `/etc/apache2/sites-available/000-default.conf` (o el equivalente Tomcat / mod_jk):

   ```apache
   <Proxy "balancer://si2cluster">
       BalancerMember http://10.1.99.1:25080 route=Instance01
       BalancerMember http://10.1.99.1:28081 route=Instance02
       ProxySet stickysession=JSESSIONID|jsessionid     # asegurar sticky
       ProxySet lbmethod=byrequests
   </Proxy>

   Header add Set-Cookie "JSESSIONID=%{JSESSIONID}e.Instance01; path=/" \
       env=BALANCER_ROUTE_CHANGED                        # asegurar sufijo
   ```

2. Verificar y reiniciar:
   ```bash
   sudo apachectl configtest
   sudo systemctl restart apache2
   ```

3. Borrar cookies del navegador.

4. Repetir el flujo de pago. Confirmar:
   - Cookie tiene formato `XXX.InstanceYY`.
   - Pago se completa sin error.
   - En balancer-manager, el contador Elected incrementa solo en una instancia para el cliente.

5. Comprobar también que las dos instancias comparten BD y SECRET_KEY de Django (sino cada una valida CSRF distinto).
