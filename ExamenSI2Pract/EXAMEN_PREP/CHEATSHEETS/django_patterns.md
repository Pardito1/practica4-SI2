# Cheatsheet — Patrones Django (añadir un campo nuevo a un modelo)

> **El ejercicio típico del examen** consiste en: copiar `P1-base` a `P1-base-ex`, añadir un campo nuevo (ej. `concepto`, `anticipado`, `correoConfirmacion`) a la entidad principal (`Pago`, `Voto`, lo que toque), modificarlo en TODA la pila (modelo + form + template + DAO + migración SQL), probar y pegar `SELECT * FROM tabla;` en `Ejercicio1.txt` (o donde diga el examen).

## Estructura de P1-base (referencia rápida)

```
P1-base/
├── manage.py
├── env                          # variables: DATABASE_SERVER_URL, SECRET_KEY, DEBUG
├── requirements.txt
├── visaApp/
│   ├── models.py                # clases Tarjeta, Pago
│   ├── forms.py                 # PagoForm, TarjetaForm, GetPagosForm, DelPagoForm
│   ├── pagoDB.py                # capa DAO con queries ORM
│   ├── views.py                 # aportarinfo_pago, aportarinfo_tarjeta, testbd, getpagos, delpago
│   ├── urls.py                  # rutas de la app
│   ├── templates/
│   │   ├── template_pago.html
│   │   ├── template_tarjeta.html
│   │   ├── template_test_bd.html
│   │   ├── template_exito.html
│   │   ├── template_get_pagos_result.html
│   │   └── template_mensaje.html
│   ├── migrations/
│   │   └── 0001_initial.py
│   └── management/commands/
│       ├── data.csv             # tarjetas para poblar
│       └── populate.py
└── visaSite/
    ├── settings.py              # ALLOWED_HOSTS=['*'], SESSION_ENGINE='cache'
    ├── urls.py                  # include('visaApp.urls') con prefijo /visaApp/
    └── wsgi.py
```

## Patrón "Añadir campo `X` a la entidad `E`"

Supongamos: el examen pide añadir un campo `concepto` (varchar(30)) a `Pago`.

### Paso 1 — Copiar P1-base a P1-base-ex

```bash
[HOST] cd ~/practica4-SI2/SI2EXTxPyyApellidoNombre
[HOST] cp -r ../ExamenSI2Pract/SI2P1_2311_AlejandroPablo/SI2-P1-entrega/P1-base ./P1-base-ex
[HOST] cd P1-base-ex
[HOST] ls
```

### Paso 2 — Modificar `models.py`

En `visaApp/models.py`, añadir el campo en la clase `Pago`:

```python
class Pago(models.Model):
    """Definición del modelo para registrar un pago"""
    idComercio = models.CharField(max_length=16)
    idTransaccion = models.CharField(max_length=16)
    importe = models.FloatField()
    tarjeta = models.ForeignKey(Tarjeta, on_delete=models.CASCADE)
    marcaTiempo = models.DateTimeField(auto_now=True)
    codigoRespuesta = models.CharField(max_length=3,
                                       default=CodigoRespuesta.RESPUESTA_OK)
    concepto = models.CharField(max_length=30, default='')   # <<< NUEVO

    class Meta:
        constraints = [UniqueConstraint(fields=['idTransaccion', 'idComercio'],
                                        name='unique_blocking_pago')]
        db_table = 'pago'
```

> Si el examen dice que el campo es **NOT NULL sin default**, deja `default=''` igualmente para no romper la migración. Después puedes quitarlo si quieres.

### Paso 3 — Modificar `forms.py`

En `visaApp/forms.py`:

```python
class PagoForm(forms.Form):
    idComercio = forms.CharField(label='ID Comercio', required=True)
    idTransaccion = forms.CharField(label='ID Transaccion', required=True)
    importe = forms.FloatField(label='Importe', required=True)
    concepto = forms.CharField(label='Concepto', max_length=30, required=True)   # <<< NUEVO
```

### Paso 4 — Modificar plantillas (si el examen las menciona)

Las plantillas usan `{{ form.as_p }}`, así que el campo nuevo aparece **automáticamente** sin tocar nada. Pero si el examen pide HTML específico (típico cuando da el `<tr><td>...</td></tr>`), edítalo a mano.

Por ejemplo, si el enunciado dice:
```html
<tr>
  <td>Concepto: </td>
  <td><input type="text" name="Concepto" maxlength="30" size="20" /></td>
</tr>
```

> ⚠️ Atención al `name`: si el enunciado dice `name="Concepto"` (mayúscula), tu form Django debe tener el field como `Concepto` también, o el POST no se mapeará. El nombre del field en `forms.py` debe coincidir con el `name=` del HTML.

### Paso 5 — Modificar `pagoDB.py` (si hace falta)

Como `Pago.objects.create(**pago_dict)` recoge cualquier campo que esté en el modelo y en el dict, **normalmente NO hay que tocar `pagoDB.py`** si el campo simplemente se persiste tal cual.

Solo tocar si el examen pide lógica especial (validar el campo, transformar, etc.).

### Paso 6 — Modificar `views.py` (si hace falta)

`aportarinfo_pago` ya recoge `pago_form.cleaned_data` entero, así que el campo nuevo viaja sin tocar nada. **Normalmente NO hay que tocar `views.py`**.

Solo tocar si el examen pide algún procesamiento del campo o pasarlo a la sesión, etc.

### Paso 7 — Migración

```bash
[VM] cd ~/P1base   # o donde tengas la copia trabajada
[VM] source ~/venv/bin/activate
[VM] python manage.py makemigrations visaApp
# Te creará algo como 0002_pago_concepto.py
[VM] python manage.py migrate
```

> ⚠️ Si trabajas en P1-base-ex en el HOST y no en `~/P1base` de la VM, necesitas SCP. Mira "Workflow alternativo" abajo.

### Paso 8 — Probar

```bash
[VM] curl -s http://127.0.0.1:8000/visaApp/tarjeta/ | head -10
```

O en el navegador del HOST: `http://localhost:18000/visaApp/tarjeta/` y rellenar el formulario.

### Paso 9 — Pegar SELECT en EjercicioN.txt

```bash
[VM] sudo -u postgres psql -d si2db -c 'SELECT * FROM pago;'
```

Copiar la salida y pegarla en `~/practica4-SI2/SI2EXTxPyyApellidoNombre/EjercicioN.txt`.

---

## Workflow alternativo (recomendado): trabajar en HOST y desplegar a VM

Si el examen te pide entregar `P1-base-ex/` como carpeta, es más cómodo trabajar fuera de la VM (en el repo donde tienes Claude Code) y solo mandar a la VM cuando necesites probar.

### Opción A — SCP completo cada vez que pruebas

```bash
[HOST] cd ~/practica4-SI2/SI2EXTxPyyApellidoNombre
[HOST] scp -P 12022 -r P1-base-ex si2@localhost:/home/si2/P1-base-ex
[VM]   cd ~/P1-base-ex
[VM]   source ~/venv/bin/activate
[VM]   python manage.py makemigrations visaApp && python manage.py migrate
[VM]   python manage.py runserver 0.0.0.0:8000
```

### Opción B — rsync diferencial (más rápido)

```bash
[HOST] rsync -avz -e "ssh -p 12022" \
        --exclude '__pycache__' --exclude '*.pyc' \
        ~/practica4-SI2/SI2EXTxPyyApellidoNombre/P1-base-ex/ \
        si2@localhost:/home/si2/P1-base-ex/
```

### Opción C — trabajar SOLO en la VM

Editar dentro de la VM con `nano`/`vim`:
```bash
[VM] cd ~/P1-base-ex && nano visaApp/models.py
```

Y al final descargar al HOST para meter en la entrega:
```bash
[HOST] scp -P 12022 -r si2@localhost:/home/si2/P1-base-ex \
        ~/practica4-SI2/SI2EXTxPyyApellidoNombre/P1-base-ex
```

Yo (Claude) recomiendo **Opción A** porque es la que menos errores genera y permite que el código quede en el repo controlado por git.

---

## Errores típicos y cómo arreglarlos

### `django.db.utils.OperationalError: connection refused`
PostgreSQL parado. `sudo systemctl start postgresql`.

### `relation "pago" does not exist`
No has migrado. `python manage.py migrate`.

### `column "concepto" does not exist`
Has tocado el modelo pero NO has migrado, o has olvidado `makemigrations`.
```bash
python manage.py makemigrations visaApp && python manage.py migrate
```

### `null value in column "concepto" violates not-null constraint`
El campo es `NOT NULL` y no has dado `default`. Soluciones:
- Añadir `default=''` en el modelo y migrar de nuevo.
- O insertar pasando el campo siempre.

### `duplicate key value violates unique constraint "unique_blocking_pago"`
Estás insertando un pago con `(idComercio, idTransaccion)` ya existente. Cambia los IDs o `DELETE FROM pago` antes.

### `CSRF verification failed`
Te has olvidado `{% csrf_token %}` en el template, o el `name` del input no coincide con el del form.

### Tras tocar el modelo, gunicorn no recoge el cambio
```bash
[VM] sudo systemctl restart gunicorn
```

### "no module named X" tras añadir un import
Activar el venv: `source ~/venv/bin/activate`. Si el módulo no existe: `pip install X`.

---

## Comandos útiles del shell de Django

```bash
[VM] python manage.py shell
>>> from visaApp.models import Pago, Tarjeta
>>> Tarjeta.objects.count()
>>> p = Pago.objects.first()
>>> p.idComercio, p.importe, p.concepto    # comprueba que el campo nuevo se ve
>>> Pago.objects.filter(idComercio='X').values()
```

---

## Variantes del modelo según el examen

Si el examen cambia la entidad (`pago` → `voto`, etc.), las traducciones probables son:

| Pago (P1-base original) | Voto (exámenes 2024) |
|---|---|
| `Pago` (clase) | `Voto` (clase) |
| `idComercio` | `idMesaElectoral` o `idMesa` |
| `idTransaccion` | `idVoto` o `idProcesoElectoral` |
| `importe` | (no hay equivalente) |
| `tarjeta` (FK) | `candidato` (CharField o FK) |
| `pagoDB.py` | `votoDB.py` |
| `template_pago.html` | `template_voto.html` |
| `aportarinfo_pago` | `aportarinfo_voto` o `registrar_voto` |

> Pero si el examen NO da una nueva entidad y sigue siendo `Pago` → `Pago`, no inventes. Lee literal.
