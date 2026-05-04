# Cheatsheet — Traducción de los enunciados (JSF/JSP) a Django

> **Crítico**: los exámenes están escritos pensando en una versión antigua de la asignatura que usaba **servlets/JSP/JSF + Tomcat** + `build.properties` + `*.xhtml`. Vosotros lo hacéis en **Django**. Tenéis que traducir mentalmente.

## Tabla de equivalencias

| Enunciado dice | Django equivale a |
|---|---|
| `build.properties` | No existe. Si pide cambiar el "nombre del proyecto", renombra carpeta y modifica `manage.py` y `wsgi.py` references. Para entrega: se ignora. |
| `name="P1-base-ex"` | Renombrar la carpeta a `P1-base-ex`. Si la app interna tiene name (`visaApp`) y el proyecto (`visaSite`), no hace falta tocarlos. |
| `*.xhtml` | `*.html` en `visaApp/templates/` |
| `testbd.xhtml` / `testbd.jsp` | `template_test_bd.html` |
| `pago.html` / `pago.xhtml` / `pago.jsp` | `template_pago.html` (o `template_tarjeta.html` para el primer paso) |
| `voto.xhtml` | `template_voto.html` (a crear si no existe) |
| `<h:inputText id="x" value="#{bean.x}" required="true" />` | `<input type="text" name="x" required>` (Django form se encarga del binding) |
| `<h:selectOneRadio>` con `<f:selectItem itemValue="#{true}" itemLabel="Si"/>` | `<input type="radio" name="x" value="True"> Si <input type="radio" name="x" value="False"> No` |
| `<h:inputText maxlength="50" />` | `<input type="text" name="x" maxlength="50">` |
| `requiredMessage="..."` | Mensaje `required` se gestiona en Django con `forms.CharField(required=True, error_messages={'required': '...'})` |
| `VotoBean` (objeto Java) | `Voto` (modelo Django en `models.py`) |
| `VotoBean.anticipado = true` | `voto.anticipado = True` (Python) |
| `VotoDAO` | `votoDB.py` (capa de acceso a datos) — equivale a `pagoDB.py` |
| `VisaDAO` | `pagoDB.py` o `visaDB.py` |
| `getter / setter` (Java) | Django models: el campo es atributo directo. No hace falta crear `get_x()`/`set_x()`. Si el examen los exige, añade properties: `@property def x(self): return self._x` (raro). |
| `create.sql` (script SQL inicial) | `migrations/0001_initial.py` (Django lo genera) |
| `alter table pago add column concepto char(30) not null;` | Añadir `concepto = models.CharField(max_length=30)` al modelo + `python manage.py makemigrations && migrate` |
| `JSESSIONID` | `ROUTEID` (cookie de sticky session) |
| `JSESSIONID.Instance01` | `ROUTEID=.Instance01` |
| `mod_jk` (Tomcat connector) | `mod_proxy_balancer` (Apache) |
| `Tomcat instances` (Instance01...) | `BalancerMember` (Instance01...) en mod_proxy_balancer |
| Servlet `ComienzaPago` | View `aportarinfo_tarjeta` |
| Servlet `ProcesaPago` | View `aportarinfo_pago` |
| `request.getSession().setAttribute("x", v)` | `request.session['x'] = v` |
| `request.getSession().getAttribute("x")` | `request.session.get('x')` |
| `response.sendRedirect("pago.xhtml")` | `return redirect('pago')` |
| `<form action="ProcesaPago" method="post">` | `<form method="post" action="{% url 'pago' %}">{% csrf_token %}` |
| Conexión JDBC con queries preparadas | Django ORM (`Pago.objects.create(...)`) o `cursor.execute("INSERT...", [params])` para raw queries |
| `ResultSet rs = stmt.executeQuery(...)` | `Pago.objects.filter(...)` o `cursor.fetchall()` |

## Patrón "modificar el bean Java" → "modificar el modelo Django"

### Java original (lo que asume el enunciado)
```java
public class VotoBean {
    private boolean anticipado;
    public boolean isAnticipado() { return anticipado; }
    public void setAnticipado(boolean anticipado) { this.anticipado = anticipado; }
}
```

### Django equivalente
```python
class Voto(models.Model):
    # ... otros campos ...
    anticipado = models.BooleanField(default=False)
```

Y en el form:
```python
class VotoForm(forms.Form):
    # ... otros campos ...
    anticipado = forms.BooleanField(required=False)   # checkbox
    # o forms.ChoiceField(choices=[(True,'Si'),(False,'No')], widget=forms.RadioSelect) para radio
```

## Patrón "modificar VotoDAO" → "modificar el ORM"

### Java original
```java
public void registrarVoto(VotoBean v) {
    String sql = "INSERT INTO voto (id, anticipado) VALUES (?, ?)";
    PreparedStatement ps = conn.prepareStatement(sql);
    ps.setInt(1, v.getId());
    ps.setBoolean(2, v.isAnticipado());
    ps.executeUpdate();
}
```

### Django ORM (recomendado)
```python
def registrar_voto(voto_dict):
    voto = Voto.objects.create(**voto_dict)
    return voto
```

### Django raw query (si el examen exige "queries preparadas")
```python
from django.db import connection

def registrar_voto(voto_dict):
    with connection.cursor() as cursor:
        cursor.execute(
            "INSERT INTO voto (id, anticipado) VALUES (%s, %s)",
            [voto_dict['id'], voto_dict['anticipado']]
        )
```

> El enunciado a veces dice "tanto queries preparadas como no preparadas". En Django con ORM ya está cubierto (Django escapa parámetros automáticamente). Si quieren ver queries SQL crudas, usar `cursor.execute(...)` con placeholders `%s`.

## Patrón "modificar formulario JSF" → "modificar template Django"

### JSF / JSP original
```html
<h:form>
    <h:inputText id="anticipado" value="#{votoBean.anticipado}" required="true" />
    <h:commandButton value="Enviar" action="#{votoBean.registrar}" />
</h:form>
```

### Django template
```html
<form method="post">
    {% csrf_token %}
    <input type="text" name="anticipado" required>
    <button type="submit">Enviar</button>
</form>
```

O usando Django forms:
```html
<form method="post">
    {% csrf_token %}
    {{ form.as_p }}
    <button type="submit">Enviar</button>
</form>
```

## Cuando el enunciado da el HTML literal (caso 22-23)

```html
<tr>
  <td>Concepto: </td>
  <td><input type="text" name="Concepto" maxlength="30" size="20" /></td>
</tr>
```

**Pégalo TAL CUAL** en el template, dentro del `<table>` que tenga el resto de campos. Después en el form:
```python
class PagoForm(forms.Form):
    # ...
    Concepto = forms.CharField(max_length=30, required=True)   # MISMO nombre que el HTML
```

> ⚠️ **El nombre del campo en `forms.py` debe coincidir EXACTAMENTE con el `name` del HTML** (incluyendo mayúsculas/minúsculas), o Django no hará el binding del POST.

## Patrón "alter table" SQL → migración Django

### SQL original
```sql
alter table voto add column anticipado BOOLEAN default FALSE;
```

### Django approach (recomendado, automático)
1. Modificar `models.py`:
   ```python
   class Voto(models.Model):
       # ...
       anticipado = models.BooleanField(default=False)
   ```
2. Generar y aplicar migración:
   ```bash
   python manage.py makemigrations visaApp
   python manage.py migrate
   ```

### Si el examen quiere ver el ALTER literal
Ejecutar a mano además:
```bash
sudo -u postgres psql -d si2db -c "ALTER TABLE voto ADD COLUMN anticipado BOOLEAN DEFAULT FALSE;"
```

> Pero si Django ya lo ha hecho con migración, intentar el ALTER de nuevo dará `ERROR: column "anticipado" of relation "voto" already exists`. Solo lo haces TÚ a mano si no usas Django para esto.

## Conclusión

Cuando leas el enunciado, **traduce conceptualmente** al stack Django pero **respeta los nombres exactos** de campos, atributos HTML y entidades que pida.

Si el enunciado es ambiguo en una traducción, **pregunta al profesor** o documenta tu interpretación en el `EjercicioN.txt`:

> "Como el enunciado se refiere al stack JSF/Tomcat, hemos interpretado:
> - `VotoBean` como modelo `Voto` en Django.
> - `VotoDAO.registrarVoto` como `votoDB.registrar_voto`.
> - El campo `anticipado` se ha añadido como `BooleanField(default=False)` y la migración Django (`makemigrations`+`migrate`) genera el `ALTER TABLE` automáticamente."

Eso curte la entrega frente a un evaluador estricto.
