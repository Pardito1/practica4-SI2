# Cheatsheet — Formato de entrega

## Naming del archivo `.tar.gz`

Patrón visto en exámenes pasados:
```
SI2EXTxPyyApellido1Apellido2Nombre.tar.gz
```

Donde:
- `x` = código de turno (en los exámenes 22-23 y 2024 vimos `2361`, `01`, etc. — **MIRA EL ENUNCIADO** del examen, ahí debe especificarlo).
- `yy` = número de pareja (asignado por el profesor; en los pasados era `01`, `02`...).
- Se escriben **ambos apellidos del estudiante (no de la pareja)** y luego el nombre.
- **Sin espacios**, **sin tildes**, **sin caracteres raros**.

### Ejemplos reales de exámenes pasados
```
SI2EXT2361P01PerezGarciaAndres.tar.gz       # 22-23
SI2EXT2311P[YY]PardoPolloAlejandro.tar.gz   # propuesta para vosotros si turno = 2311
```

> 🔥 **Mira el enunciado del examen para saber el `x` y el `yy` exactos**. No los inventes.

## Estructura del `.tar.gz`

El `.tar.gz` debe contener **una sola carpeta raíz** con el mismo nombre (sin la extensión `.tar.gz`):

```
SI2EXT2311P01PardoPolloAlejandro.tar.gz
└── SI2EXT2311P01PardoPolloAlejandro/
    ├── Ejercicio1.txt
    ├── Ejercicio2.txt
    ├── Ejercicio3.txt
    ├── P2.jmx                    # solo si el examen lo pide en Ej2
    └── P1-base-ex/                # solo si el examen lo pide en Ej1 o Ej3
        ├── manage.py
        ├── env
        ├── requirements.txt
        ├── visaApp/
        │   ├── models.py        # modificado
        │   ├── forms.py         # modificado
        │   ├── pagoDB.py        # modificado si aplica
        │   ├── views.py
        │   ├── templates/
        │   │   └── ...html
        │   └── migrations/
        │       ├── 0001_initial.py
        │       └── 0002_<algo>.py    # tu migración nueva
        └── visaSite/
            ├── settings.py
            ├── urls.py
            └── wsgi.py
```

> ⚠️ El nombre de la carpeta raíz **DEBE coincidir** con el del archivo (sin `.tar.gz`).

## Comando para crear el `.tar.gz`

```bash
[HOST] cd ~/practica4-SI2
[HOST] tar -czvf SI2EXT2311P01PardoPolloAlejandro.tar.gz SI2EXT2311P01PardoPolloAlejandro/
[HOST] ls -lh SI2EXT2311P01PardoPolloAlejandro.tar.gz
[HOST] tar -tzvf SI2EXT2311P01PardoPolloAlejandro.tar.gz | head -30   # verificar
```

Mejor usar el script `crear_entrega.sh` que está en `EXAMEN_PREP/PLANTILLAS/`. Hace la limpieza de `__pycache__`, `.pyc`, `env`, `venv`, etc. automáticamente.

## Qué INCLUIR

- **Ejercicio1.txt, Ejercicio2.txt, Ejercicio3.txt**: textos plano con respuestas y outputs SQL.
- **P2.jmx (modificado)**: el script JMeter editado según las condiciones del Ej2 (si aplica).
- **P1-base-ex/**: la copia de `P1-base` con tus modificaciones (si aplica).
- Cualquier fichero auxiliar que el examen pida explícitamente.

## Qué NO incluir

- ❌ `__pycache__/`, `*.pyc`, `*.pyo`
- ❌ `venv/`, `env/` (virtualenv) — pero el fichero `env` (sin extensión) que tiene las variables sí, salvo que contenga credenciales reales sensibles
- ❌ `db.sqlite3` (no usamos sqlite, pero por si acaso)
- ❌ `.git/`, `.idea/`, `.vscode/`, `.DS_Store`
- ❌ Las carpetas `migrations/0002_*` autogeneradas por la rama del compañero (cada uno entrega solo SU migración)
- ❌ Capturas, fotos, PDFs (todo va en texto)
- ❌ La VM, las copias de seguridad, etc.

## Plantilla de `EjercicioN.txt`

Mira `EXAMEN_PREP/PLANTILLAS/Ejercicio*.txt` para los esqueletos.

Pero la regla general:

```
EJERCICIO N — [Título corto]
============================

[Resumen de lo que pedía el enunciado en 1-2 líneas]

PASOS REALIZADOS
----------------
1. [Acción concreta]
2. ...
N. ...

CÓDIGO/CONFIG MODIFICADO
------------------------
[Snippets clave del código que has cambiado, si procede]

PRUEBA / VERIFICACIÓN
----------------------
[Comando ejecutado y output literal]

RESULTADO SQL (si aplica)
-------------------------
si2db=# SELECT * FROM <tabla>;
[output completo, no truncar]

DISCUSIÓN (opcional pero recomendado)
-------------------------------------
[Justificación de decisiones de diseño, traducciones de JSF→Django, etc.]
```

## Comprobaciones finales antes de subir a Moodle

Hazlas SIEMPRE, en este orden, antes del countdown final:

1. **Visual sanity check** del `.tar.gz`:
   ```bash
   tar -tzvf MI_ENTREGA.tar.gz
   ```
   Comprobar:
   - Sí está la carpeta raíz `SI2EXT...`.
   - Sí están los `EjercicioN.txt`.
   - Sí está `P1-base-ex/` (si aplica) con sus `.py` y `.html`.
   - **NO** hay `__pycache__/` ni `venv/`.

2. **Tamaño razonable** (entre 50 KB y unos pocos MB):
   ```bash
   du -h MI_ENTREGA.tar.gz
   ```
   Si pesa > 10 MB, casi seguro tienes basura dentro.

3. **Test de extracción**:
   ```bash
   mkdir /tmp/test_entrega && cd /tmp/test_entrega
   tar xzf ~/practica4-SI2/MI_ENTREGA.tar.gz
   ls -la
   cat */Ejercicio1.txt | head
   ```

4. **Subir a Moodle** y comprobar que aparece en la lista de entregas.

5. **Backup en pendrive** (red de seguridad):
   ```bash
   cp MI_ENTREGA.tar.gz /media/$USER/PENDRIVE/
   sync
   ```

## Si el archivo es demasiado grande para Moodle

Moodle suele aceptar hasta 50 MB. Tu entrega bien hecha estará en KB-pocos MB. Si pesa más:
1. Comprueba que no incluyes `venv/` ni `__pycache__/`.
2. Comprueba que `P1-base-ex` no tiene `db.sqlite3` u otros artefactos.
3. Si tienes capturas grandes en los `.txt` (no debería), recórtalas.

## Si algo se te olvida

Después de entregar el `.tar.gz`, Moodle suele permitir reemplazarlo varias veces hasta el cierre. **Verifica que la última versión que subes es la buena**.

## Naming de la rama de git (para tu trabajo, no se entrega)

```
examen/alejandro
examen/pablo
```

Estas ramas **NO se mergean a `main`** durante el examen. Quedan como histórico de tu trabajo. Si quieres, después del examen las puedes mergear o eliminar.
