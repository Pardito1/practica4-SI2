# Cheatsheet — JMeter

> El **Ejercicio 2** del examen siempre es modificar un script `.jmx` para satisfacer condiciones específicas (X usuarios × Y iteraciones, IDs incrementales, valores aleatorios desde lista, etc.).

## Localización del script de partida

```
ExamenSI2Pract/SI2P3_2311_Parte1/P3-projects.jmx
ExamenSI2Pract/SI2P3_2311_Parte1/P3_P1-base.jmx
ExamenSI2Pract/SI2P4_2311_AlejandroPablo/SI2P4_2311_AlejandroPablo/P4_P1-base.jmx
P4_P1-base.jmx                       # raíz del repo
```

El examen pedirá modificar uno de estos (probablemente el `P3_P1-base.jmx` o el `P4_P1-base.jmx`). Léelo primero.

## Flujo de trabajo

JMeter **NO se debería ejecutar dentro de la VM** salvo que ya esté instalado. Lo normal: ejecutar JMeter en el HOST contra `localhost:18000` (que llega a Django de la VM por el port-forward).

### Si JMeter no está instalado en el HOST

```bash
[HOST] cd ~ && wget https://dlcdn.apache.org/jmeter/binaries/apache-jmeter-5.6.3.tgz
[HOST] tar xzf apache-jmeter-5.6.3.tgz
[HOST] ~/apache-jmeter-5.6.3/bin/jmeter --version
```

### Lanzar el script

```bash
[HOST] ~/apache-jmeter-5.6.3/bin/jmeter -n -t mi_script.jmx -Jhost=localhost -Jport=18000 -l results.jtl
```

> ⚠️ **NO uses la versión `apt` (2.13)**: rompe con `XStream ForbiddenClassException` al cargar JMX modernos.

## Estructura típica del JMX

Los `.jmx` que tenéis tienen aproximadamente:

```
Test Plan
├── Thread Group (Number of Threads, Loop Count, Ramp-Up Period)
│   ├── HTTP Cookie Manager (Clear Cookies each Iteration: ✓)
│   ├── HTTP Request Defaults (host=${host}, port=${port}, path=/visaApp/)
│   ├── HTTP Request: GET /tarjeta/
│   │   └── Regular Expression Extractor (csrfmiddlewaretoken)
│   ├── HTTP Request: POST /aportarinfo_pago/ (con csrf token)
│   │   └── Regular Expression Extractor (csrf token siguiente)
│   ├── HTTP Request: POST /pago/ (con csrf token)
│   ├── CSV Data Set Config (data.csv → numero, expiracion, cvv)
│   └── (View Results Tree, Aggregate Report — solo en GUI)
```

## Modificaciones típicas que pide el examen

### 1. Cambiar número de hilos / loops

En `<ThreadGroup>`:
```xml
<ThreadGroup ...>
  <stringProp name="ThreadGroup.num_threads">100</stringProp>     <!-- usuarios -->
  <stringProp name="ThreadGroup.ramp_time">10</stringProp>        <!-- segundos -->
  <elementProp name="ThreadGroup.main_controller" elementType="LoopController">
    <stringProp name="LoopController.loops">25</stringProp>       <!-- iteraciones por usuario -->
  </elementProp>
</ThreadGroup>
```

> **Total de iteraciones = num_threads × loops**.
> Ejemplo enunciado 2024 tarde: 100 usuarios × 25 votos = 2500 votos esperados.
> Ejemplo enunciado 22-23 (P2.jmx): 20 usuarios × 225 pagos = 4500 pagos.

### 2. ID incremental (counter) con offset y paso

JMeter tiene un **Counter element**. Añadir como hijo del Thread Group:

```xml
<Counter guiclass="CounterConfigGui" testclass="Counter" testname="ID Mesa Electoral" enabled="true">
  <stringProp name="CounterConfig.start">130</stringProp>     <!-- valor inicial -->
  <stringProp name="CounterConfig.end">9999999</stringProp>
  <stringProp name="CounterConfig.incr">10</stringProp>       <!-- paso -->
  <stringProp name="CounterConfig.name">idMesa</stringProp>   <!-- nombre variable -->
  <stringProp name="CounterConfig.format"></stringProp>
  <boolProp name="CounterConfig.per_user">false</boolProp>    <!-- false = compartido entre todos los hilos -->
</Counter>
```

Y en la HTTPRequest del POST, usar `${idMesa}` en el body.

### 3. Valor aleatorio de una lista (ej. candidatos)

Dos formas:
- **CSV** (recomendado, más limpio):
  Crear `candidatos.csv` con una columna:
  ```
  Pepe Pérez
  Belén Ruiz
  Juan López
  Ana Gómez
  ```
  Y un `CSV Data Set Config`:
  ```xml
  <CSVDataSet guiclass="TestBeanGUI" testclass="CSVDataSet" testname="Candidatos" enabled="true">
    <stringProp name="filename">candidatos.csv</stringProp>
    <stringProp name="variableNames">candidato</stringProp>
    <stringProp name="recycle">true</stringProp>
    <stringProp name="stopThread">false</stringProp>
    <stringProp name="shareMode">shareMode.all</stringProp>
  </CSVDataSet>
  ```
  Usa `${candidato}` en el body POST.

- **Random Variable** (función inline):
  ```
  ${__chooseRandom(Pepe Pérez,Belén Ruiz,Juan López,Ana Gómez,candidato)}
  ```
  Pero esta función no viene con JMeter de serie, requiere el plugin Custom Functions. **Mejor usar CSV**.

### 4. Importe aleatorio entre min y max

JMeter tiene `__Random(min, max)`:
```
${__Random(150,500,importe)}
```
Devuelve un entero entre 150 y 500 y lo guarda en `${importe}`. Usa esa variable en el body.

### 5. Limpiar cookies en cada iteración

En el `HTTP Cookie Manager`:
```xml
<CookieManager ...>
  <boolProp name="CookieManager.clearEachIteration">true</boolProp>
</CookieManager>
```

Esto es crítico para los exámenes: si NO se limpian, todas las iteraciones de un mismo hilo van al mismo balanceador-instance (sticky session).

### 6. Cambiar el host/port

Si el examen pide ejecutar contra una IP específica:
- O modificar `HTTP Request Defaults` directamente.
- O pasarlo por `-Jhost=...` desde la línea de comandos (lo que tenemos):
  ```xml
  <stringProp name="HTTPSampler.domain">${__P(host,localhost)}</stringProp>
  <stringProp name="HTTPSampler.port">${__P(port,18000)}</stringProp>
  ```

### 7. CSRF Token (Django lo exige en POST)

Tras el GET inicial, extraer el token con un `Regular Expression Extractor` como **hijo del HTTPRequest GET**:
```xml
<RegexExtractor guiclass="RegexExtractorGui" testclass="RegexExtractor" testname="Extract CSRF" enabled="true">
  <stringProp name="RegexExtractor.refname">csrf</stringProp>
  <stringProp name="RegexExtractor.regex">name="csrfmiddlewaretoken" value="([^"]+)"</stringProp>
  <stringProp name="RegexExtractor.template">$1$</stringProp>
  <stringProp name="RegexExtractor.default">notfound</stringProp>
</RegexExtractor>
```

Y en el siguiente POST, añadir el parámetro:
- nombre: `csrfmiddlewaretoken`
- valor: `${csrf}`

> Ya está hecho en los JMX que tenéis (es el addendum del profesor).

## Cómo investigar discrepancias (Ej2.2 examen 2024)

Si JMeter reporta `Err: 0.00%` pero la BD tiene MENOS pagos/votos de los esperados, el problema es **silencioso**: las peticiones tienen 200 OK pero el servidor las rechaza. Posibles causas:
- Constraint duplicado: `unique_blocking_pago` en `(idComercio, idTransaccion)` rechaza pagos con misma combinación → la app responde con un mensaje de error pero HTTP 200.
- CSRF inválido: el token caducó o no se extrajo bien → la vista responde 403 pero solo si `Response Assertion` lo detecta.
- Problema de sesión: Django pierde `numeroTarjeta` en `request.session` por sticky session no aplicado.

**Cómo investigar dentro de JMeter**:
1. Abrir JMeter en GUI.
2. Añadir `View Results Tree` como listener al Test Plan.
3. Lanzar 5-10 iteraciones.
4. Inspeccionar la pestaña "Response data" de cada petición — ¿devuelve el HTML del formulario en lugar del éxito?
5. Añadir `Aggregate Report` para ver throughput y comprobar que la BD recibe pagos al ritmo esperado.
6. Añadir `Assertion Results` para ver si las assertions están detectando el problema.
7. Comparar: nº de iteraciones JMeter vs `SELECT COUNT(*) FROM pago`.

## Variables JMeter útiles (built-in)

| Variable | Significado |
|---|---|
| `${__threadNum}` | número del hilo actual (1..N) |
| `${__time(yyyy-MM-dd_HH-mm-ss)}` | timestamp formateado |
| `${__UUID}` | UUID aleatorio único |
| `${__counter(true)}` | contador per-thread (cada hilo cuenta independiente) |
| `${__counter(false)}` | contador global (compartido) |
| `${__Random(min,max,var)}` | aleatorio entero |
| `${__RandomString(len,chars,var)}` | string aleatorio de longitud `len` |
| `${__P(prop,default)}` | leer property `-Jprop=valor` desde línea de comandos |

## Resultados de la prueba

Tras lanzar:
```bash
[HOST] ~/apache-jmeter-5.6.3/bin/jmeter -n -t script.jmx -Jhost=localhost -Jport=18000 -l results.jtl
```

Ver resumen en stdout. Para análisis posterior:
```bash
[HOST] ~/apache-jmeter-5.6.3/bin/jmeter -g results.jtl -o ./report-html
[HOST] firefox ./report-html/index.html
```

Pero para el examen, lo importante es:
- El stdout final con `summary = N in HH:MM:SS = X/s   Avg: ...   Err: N (X.XX%)`.
- El `SELECT COUNT(*) FROM <tabla>;` posterior para confirmar que cuadra.

Pegar ambos en el `EjercicioN.txt`.
