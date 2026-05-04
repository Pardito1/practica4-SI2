# Examen SI2 2024 (grupo TARDE) — Análisis y solución razonada

> Origen: `wuolah-free-Examen(grupo tarde)-practicas-SI2-2024.pdf`. Mayo 2024.

## Datos formales

- Mismo formato `.tar.gz` que los anteriores, con `Ejercicio1.txt`, `Ejercicio2.txt`, `Ejercicio3.txt`, P1-base-ex y P2.jmx.

## Ejercicio 1 — P1-base + nuevo campo "correoConfirmacion"

### Lo que pedía

Estructura idéntica al Ej3 del 2024 mañana o Ej1 del 22-23, pero:

- Entidad: **VOTO**.
- Nuevo campo: `correoConfirmacion` (varchar(50), NOT NULL).
- HTML que da el enunciado:
  ```html
  <tr>
    <td>Correo de confirmación</td>
    <td>
      <h:inputText id="correoConfirmacion" title="Correo de confirmación:"
                   value="#{votoBean.correoConfirmacion}" required="true"
                   requiredMessage="Error: ¡se necesita un correo de confirmación!"
                   maxlength="50" />
    </td>
  </tr>
  ```
- SQL: `alter table voto add column correo varchar(50) not null;`
- Modificar `VotoDAO` para incluir el nuevo campo (queries preparadas y no preparadas).
- Probar con `testbd.xhtml`.
- `SELECT * FROM VOTO;` en `Ejercicio1.txt`.

### Solución

Mismo patrón que el Ej3 del 2024 mañana. Snippets:

#### `models.py`
```python
class Pago(models.Model):
    # ... resto ...
    correoConfirmacion = models.CharField(max_length=50, default='')
```

> Si el examen exige NOT NULL sin default, usar `default=''` igualmente y documentar la decisión, o ejecutar manualmente `ALTER TABLE pago ALTER COLUMN correoConfirmacion DROP DEFAULT;` después.

#### `forms.py`
```python
class PagoForm(forms.Form):
    # ... resto ...
    correoConfirmacion = forms.CharField(
        label='Correo de confirmación',
        max_length=50,
        required=True,
        error_messages={'required': 'Error: ¡se necesita un correo de confirmación!'},
    )
```

#### Templates — adaptar HTML

```html
<form method="post">
    {% csrf_token %}
    {{ pago_form.as_p }}
    <table>
        <tr>
            <td>Correo de confirmación</td>
            <td>
                <input type="text" name="correoConfirmacion" maxlength="50" required
                       title="Correo de confirmación:">
            </td>
        </tr>
    </table>
    <button type="submit">Registrar</button>
</form>
```

#### Resto

- Migrar (`makemigrations`+`migrate`).
- Probar 3-5 registros desde testbd.
- `SELECT * FROM pago;` y pegar en Ejercicio1.txt.

---

## Ejercicio 2 — JMeter: 100 usuarios × 25 votos, candidatos aleatorios

### Lo que pedía

- 100 usuarios × 25 votos = **2500 votos** sobre P1-base.
- Candidatos aleatorios entre: Pepe Pérez, Belén Ruiz, Juan López, Ana Gómez.
- ID mesa electoral empezar en 130, incrementar de 10 en 10.
- ID proceso electoral fijo = 5.
- Entregar `P2.jmx` modificado + `Ejercicio2.txt` con los pasos.

### Solución

#### Configuración del JMX

**Thread Group:**
- Number of Threads: 100
- Loop Count: 25
- Total esperado en BD: 2500

**Counter "idMesa":**
- Start: 130
- Increment: 10
- Per User: false (compartido entre hilos)
- Variable: `idMesa`

**CSV "Candidatos":**

Crear `candidatos.csv` (mismo directorio que el JMX):
```csv
Pepe Pérez
Belén Ruiz
Juan López
Ana Gómez
```

`CSV Data Set Config`:
- Filename: `candidatos.csv`
- Variable Names: `candidato`
- Sharing Mode: `All threads`
- Recycle on EOF: `True`
- Stop thread on EOF: `False`

**ID proceso electoral:** valor literal `5` en el body.

**HTTP Request POST `/voto/registrar/`** body:
```
idMesa=${idMesa}
idProcesoElectoral=5
candidato=${candidato}
csrfmiddlewaretoken=${csrf}
```

#### Comandos para lanzar

```bash
[HOST] cd ExamenSI2Pract/EXAMEN_PREP   # o donde tengas el JMX modificado
[HOST] ~/apache-jmeter-5.6.3/bin/jmeter -n -t P2.jmx \
       -Jhost=localhost -Jport=18000 -l results.jtl
```

#### Verificación

```bash
[VM] sudo -u postgres psql -d si2db -c 'SELECT COUNT(*) FROM pago;'
# Esperado: 2500
[VM] sudo -u postgres psql -d si2db -c "SELECT candidato, COUNT(*) FROM pago GROUP BY candidato;"
# Esperado: ~625 por candidato (2500/4)
```

---

## Ejercicio 3 — Preguntas teóricas (ssh-keygen, si2fixMAC.sh, virtualip.sh)

### Lo que pedía

Sobre la P3 con 3 VMs (`si2srv01`, `si2srv02`, `si2srv03`):

- a) Comando(s) para que el DAS (en si2srv01) conecte por SSH a los nodos (si2srv02, si2srv03) **sin teclear password**, asumiendo claves generadas con ssh-keygen. Indicar dónde se ejecuta cada comando.

- b) ¿Para qué sirve el script `si2fixMAC.sh`?

- c) ¿Para qué sirve `virtualip.sh`? ¿Diferencia con `si2fixMAC.sh`?

### Solución

#### a) ssh-keygen + ssh-copy-id

En la VM `si2srv01` (la del DAS):

```bash
# Generar par de claves (si no existe ya)
ssh-keygen -t rsa -b 4096
# Acepta defaults: ruta ~/.ssh/id_rsa, deja passphrase vacío.

# Copiar la clave pública a cada nodo
ssh-copy-id si2@si2srv02
ssh-copy-id si2@si2srv03
```

Esto añade el contenido de `~/.ssh/id_rsa.pub` (de si2srv01) al fichero `~/.ssh/authorized_keys` del usuario en si2srv02 y si2srv03. A partir de ese momento:

```bash
# Desde si2srv01:
ssh si2@si2srv02   # entra sin pedir password
```

**Si `ssh-copy-id` no está disponible**, equivalente manual ejecutado en si2srv01:
```bash
cat ~/.ssh/id_rsa.pub | ssh si2@si2srv02 \
    'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys'
```

#### b) `si2fixMAC.sh`

Script que **regenera las direcciones MAC** de las interfaces de red de las VMs en VirtualBox antes de arrancarlas por primera vez en los PCs del laboratorio.

**Por qué se necesita**: las VMs distribuidas a los alumnos vienen con MACs configuradas. Cuando el alumno las clona o las arranca en su PC, esas MACs pueden colisionar con las de otras VMs ya arrancadas en otros PCs de la misma red del laboratorio (capa 2). Una colisión MAC rompe la comunicación entre VMs y entre VM y red externa.

**Lo que hace**: edita el fichero `.vbox` de cada VM (XML de definición) y sustituye la MAC de cada `<Adapter>` por una nueva generada aleatoriamente, garantizando unicidad.

**Cuándo se ejecuta**: una vez, antes de arrancar las VMs en cada PC nuevo.

#### c) `virtualip.sh` y diferencia con `si2fixMAC.sh`

`virtualip.sh` configura una **IP virtual flotante** sobre una interfaz de una VM del cluster. Esta IP virtual:

- Es una IP adicional (alias) que se asigna a una de las VMs del cluster (típicamente el balanceador o el DAS).
- Sirve como **punto de entrada único** al cluster desde el exterior.
- Puede migrar entre VMs si la activa cae (high availability — HA).

**Diferencia con `si2fixMAC.sh`:**

| Aspecto | `si2fixMAC.sh` | `virtualip.sh` |
|---|---|---|
| **Capa OSI** | 2 (enlace de datos) | 3 (red) |
| **Qué modifica** | MAC address de cada interfaz | Asigna una IP adicional (alias) a una interfaz |
| **Por qué se necesita** | Evitar colisiones MAC entre VMs clonadas | Punto de acceso unificado al cluster |
| **Cuándo se ejecuta** | Una sola vez antes de arrancar VMs | Cada vez que se levanta el cluster (o tras failover) |
| **Reversibilidad** | Permanente (escribe en .vbox) | Volátil (configurada en runtime) |

**Resumen**: son **complementarios, no sustitutos**. Primero `si2fixMAC.sh` garantiza unicidad MAC. Después `virtualip.sh` define un punto de entrada IP unificado al cluster.
