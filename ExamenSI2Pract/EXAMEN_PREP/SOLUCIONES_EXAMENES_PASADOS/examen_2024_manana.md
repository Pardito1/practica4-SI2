# Examen SI2 2024 (grupo MAÑANA) — Análisis y solución razonada

> Origen: `wuolah-free-Examen-practicas-si2-2024.pdf`. Mayo 2024, 1h 50min.

## Datos formales

- **Duración**: 1h 50min.
- **Entrega**: `.tar.gz` con nombre `SI2EXTxPyyApellido1Apellido2Nombre.tar.gz`.
- **Contenido**: `Ejercicio1.txt`, `Ejercicio2.txt`, `Ejercicio3.txt` y carpeta `P1-base-ex`.
- **Puntuación**: 3 ejercicios × 10. Promedio.

⚠️ **Cambio importante respecto al 22-23**: la entidad ahora es **`voto`** en lugar de `pago`. La aplicación es de **votación electoral**, no de pagos. Las equivalencias son:

| 22-23 (pago) | 2024 (voto) |
|---|---|
| Pago | Voto |
| idComercio | idMesaElectoral / idMesa |
| idTransaccion | idVoto |
| importe | (no hay) |
| pago.html / pago.xhtml | voto.xhtml |
| testbd.jsp | testdb.xhtml |

## Ejercicio 1 — Cluster con 2 instancias, voto incorrecto

### Lo que pedía

Misma estructura que el Ej3 del 22-23, pero entidad voto:

- Cluster P3 con 2 instancias.
- Página `voto.xhtml` para registrar voto.
- Tras pulsar "Enviar", error: "View `/voto/voto.xhtml` could not be restored".
- Estado balancer-manager antes y después.

Preguntas:
1. Justificar fallo del voto si todo bien.
2. Cookie `JSESSIONID`: ¿valor `be1afff1f7615a6a33b70e584d42` o `be1afff1f7615a6a33b70e584d42.Instance01` posible?
3. Acciones para corregir.

### Solución

**[VER SOLUCIÓN COMPLETA EN `examen_22_23.md` Ej3]** — el patrón es idéntico, solo cambia "pago" por "voto" y las VMs tienen IPs `10.1.1.2:28080`, `10.1.1.3:28081` en lugar de `10.1.99.1:25080`, `10.1.99.1:28081`.

**Resumen rápido:**

1. **Por qué falla**: sticky session no aplicada → request POST cae en distinta instancia que el GET → sesión perdida (JSF state) → "view could not be restored".

2. **Cookie**: con sticky activo → valor con sufijo `.Instance01`. Sin sticky → valor pelado.

3. **Corregir**: añadir `ProxySet stickysession=JSESSIONID|jsessionid` al balancer + `Header add Set-Cookie` con sufijo de ruta. Reiniciar Apache. Borrar cookies. Reintentar.

---

## Ejercicio 2 — JMeter: 3 configuraciones de prueba

### Lo que pedía

**2.1**: Calcular cuántos votos esperar en BD para 3 configuraciones:

| Config | Hilos | Periodo subida | Loops |
|---|---|---|---|
| a | 20 | 10 seg | 5 |
| b | 50 | 15 seg | 10 |
| c | 5 | 3 seg | 1000 |

**2.2**: Si JMeter reporta 0% errores pero la BD tiene MENOS votos, ¿qué se puede hacer dentro de JMeter para investigar?

### Solución

#### 2.1 — Cálculo

`Votos esperados = Threads × Loops`:
- a) 20 × 5 = **100 votos**
- b) 50 × 10 = **500 votos**
- c) 5 × 1000 = **5000 votos**

(El periodo de subida no afecta al total, solo al ramp-up de los hilos.)

#### 2.2 — Investigar discrepancia 0% Err pero menos votos

Acciones dentro de JMeter:

1. **Añadir un `View Results Tree`** como listener al Test Plan. Lanzar JMeter en GUI con un Loop Count bajo (por ejemplo 10). Inspeccionar la pestaña **Response data** de cada POST de voto: si la respuesta HTML contiene "voto incorrecto" en lugar de "voto registrado", el servidor está aceptando con 200 OK pero rechazando el voto. JMeter por defecto solo cuenta como error los 4xx/5xx.

2. **Añadir un `Response Assertion`** a la HTTP Request del POST de voto, comprobando que el contenido contiene un texto distintivo del éxito (ej. "Voto registrado correctamente"). De este modo JMeter contará como Err los pagos rechazados silenciosamente y el `summary` se hará realista.

3. **Añadir un `Aggregate Report`** para ver throughput, p50, p99 de cada petición — descubre cuellos de botella o timeouts.

4. **Cookie Manager**: comprobar que la opción `Clear Cookies each Iteration` está activa. Si no, todas las iteraciones de un mismo hilo van al mismo backend, lo cual en cluster con BD compartida puede crear conflicto en `unique_blocking_voto` (mismo `idMesa` + `idVoto` repetido).

5. **Counter o CSV Data Set Config**: comprobar que los IDs incrementan correctamente y no se duplican entre iteraciones, porque si la BD tiene `UNIQUE(idMesa, idVoto)`, los duplicados se rechazan.

6. **Logs de Tomcat / Apache / Django**: aunque no es "dentro de JMeter", revisar `error.log` de Apache y los logs del Django/Tomcat ayuda a confirmar la causa del rechazo silencioso.

---

## Ejercicio 3 — P1-base + nuevo campo "anticipado"

### Lo que pedía

Estructura idéntica al Ej1 del 22-23 pero con entidad `voto`:

1. Copiar P1-base a P1-base-ex.
2. Modificar `build.properties` (en Django: ignorable, renombrar carpeta).
3. Una sola VM (no cluster).
4. Añadir campo `anticipado` (BOOLEAN, default FALSE) a `voto`:
   - HTML que da el enunciado:
     ```html
     <tr>
       <td>Anticipado:</td>
       <td>
         <h:selectOneRadio id="anticipado" title="anticipado"
                          value="#{votoBean.anticipado}" required="true">
           <f:selectItem itemValue="#{true}"  itemLabel="Si"/>
           <f:selectItem itemValue="#{false}" itemLabel="No"/>
         </h:selectOneRadio>
       </td>
     </tr>
     ```
   - SQL: `alter table voto add column anticipado BOOLEAN default FALSE;`
   - VotoBean: variable boolean + getter/setter.
   - VotoDAO: insertar voto con `anticipado` (queries preparadas y no preparadas).
5. Probar con `testbd.xhtml`, registros con anticipado=Si y =No.
6. `SELECT * FROM VOTO;` en `Ejercicio3.txt`.

### Solución (en Django)

#### 1. Copia
```bash
cp -r ExamenSI2Pract/SI2P1_2311_AlejandroPablo/SI2-P1-entrega/P1-base ./P1-base-ex
cd P1-base-ex
```

> **OJO**: P1-base original tiene la entidad `Pago`, no `Voto`. Como vosotros NO tenéis código de votación, hay 2 caminos:
>
> **Opción A — Renombrar Pago→Voto en toda la app**: drástico pero limpio. Requiere refactor.
>
> **Opción B — Tratar `Pago` como `Voto`**: mantener el código pero adaptar nombres en los snippets que dé el enunciado (sustituir `votoBean.anticipado` por `pagoForm.anticipado`, etc.). En el `Ejercicio3.txt` documentar esta decisión: "Como nuestra app del semestre maneja `Pago`, hemos añadido el campo `anticipado` a la entidad `Pago` interpretando que el examen pide la operación equivalente."
>
> **Recomendado: Opción B** por simplicidad y tiempo. Documentar la traducción claramente en el .txt.

#### 2. `models.py` — añadir campo

```python
class Pago(models.Model):
    # ... resto igual ...
    anticipado = models.BooleanField(default=False)   # NUEVO

    class Meta:
        constraints = [...]
        db_table = 'pago'
```

#### 3. `forms.py`

```python
class PagoForm(forms.Form):
    # ... resto ...
    anticipado = forms.ChoiceField(
        label='Anticipado',
        choices=[('True', 'Si'), ('False', 'No')],
        widget=forms.RadioSelect,
        required=True,
    )
```

#### 4. Templates — adaptar el HTML del enunciado

`template_test_bd.html`:
```html
<form method="post">
    {% csrf_token %}
    <table>
        {{ tarjeta_form.as_p }}
        <tr>{{ pago_form.idComercio.label_tag }} {{ pago_form.idComercio }}</tr>
        <tr>{{ pago_form.idTransaccion.label_tag }} {{ pago_form.idTransaccion }}</tr>
        <tr>{{ pago_form.importe.label_tag }} {{ pago_form.importe }}</tr>
        <tr>
            <td>Anticipado:</td>
            <td>
                <input type="radio" name="anticipado" value="True"> Si
                <input type="radio" name="anticipado" value="False" checked> No
            </td>
        </tr>
    </table>
    <button type="submit">Registrar Pago</button>
</form>
```

#### 5. `views.py` — convertir el string del POST a bool

```python
def aportarinfo_pago(request):
    if request.method == 'POST':
        pago_form = PagoForm(request.POST)
        # ...
        pago_data = pago_form.cleaned_data
        # Convertir anticipado de string ('True'/'False') a bool
        pago_data['anticipado'] = (pago_data.get('anticipado') == 'True')
        # ...
```

#### 6. `pagoDB.py`

ORM ya soporta el campo automáticamente con `Pago.objects.create(**pago_dict)`.

Si el examen exige queries no preparadas:
```python
def registrar_pago_raw(pago_dict):
    from django.db import connection
    with connection.cursor() as c:
        c.execute(
            "INSERT INTO pago (idComercio, idTransaccion, importe, "
            "tarjeta_id, marcaTiempo, codigoRespuesta, anticipado) "
            "VALUES (%s, %s, %s, %s, NOW(), '000', %s)",
            [pago_dict['idComercio'], pago_dict['idTransaccion'],
             pago_dict['importe'], pago_dict['tarjeta_id'],
             pago_dict['anticipado']]
        )
```

#### 7. Migración

```bash
[VM] cd ~/P1-base-ex && source ~/venv/bin/activate
[VM] python manage.py makemigrations visaApp
[VM] python manage.py migrate
```

#### 8. Probar

Navegador: `http://localhost:18000/visaApp/testbd/`
- Registrar 2 pagos con anticipado=Si.
- Registrar 2 pagos con anticipado=No.

#### 9. SELECT en Ejercicio3.txt

```bash
[VM] sudo -u postgres psql -d si2db -c 'SELECT * FROM pago;'
```

Pegar la salida.
