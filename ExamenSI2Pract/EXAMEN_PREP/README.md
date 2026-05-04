# EXAMEN_PREP — Material de preparación examen SI2 prácticas

> Esta carpeta contiene **todo lo necesario** para que cada uno de la pareja arranque su sesión de Claude Code el día del examen y trabaje con eficiencia.

## Cómo usar este material el día del examen

### 1. Antes de empezar (5 min)

Lee el fichero **`PROTOCOLO_TRABAJO.md`** entero. Es el flujo de trabajo paso a paso, desde encender la VM hasta subir el `.tar.gz` a Moodle.

### 2. Iniciar Claude Code (1 min)

Abre Claude Code en el repo. Como **primer mensaje**, **copia y pega TODO el contenido de** `PRIMER_MENSAJE.md`. Sustituye `[TU_NOMBRE]`, `[TUS_APELLIDOS]`, `[NOMBRE_COMPAÑERO]` y `[TU_RAMA]` antes de enviar.

Espera a que Claude diga "Listo, contexto cargado".

### 3. Trabajar con cada ejercicio

Sigue el flujo de **`PROTOCOLO_TRABAJO.md`** sección "Durante el examen — para CADA ejercicio".

## Estructura de esta carpeta

```
EXAMEN_PREP/
├── README.md                     ← este fichero
├── PRIMER_MENSAJE.md             ← copiar+pegar al iniciar la sesión
├── PROTOCOLO_TRABAJO.md          ← flujo de trabajo del examen
├── CHEATSHEETS/                  ← referencias rápidas que Claude lee
│   ├── vm.md                     ← acceso SSH, comandos VM, gunicorn, postgres
│   ├── django_patterns.md        ← añadir un campo nuevo a un modelo
│   ├── jmeter.md                 ← modificar el JMX
│   ├── apache_balancer.md        ← sticky session, balancer, troubleshooting
│   ├── mapeo_jsf_a_django.md     ← traducción JSF/JSP del enunciado a Django
│   └── formato_entrega.md        ← naming, estructura .tar.gz, qué incluir
├── PLANTILLAS/                   ← esqueletos para copiar
│   ├── Ejercicio1.txt
│   ├── Ejercicio2.txt
│   ├── Ejercicio3.txt
│   └── crear_entrega.sh          ← script bash para crear el .tar.gz limpio
└── SOLUCIONES_EXAMENES_PASADOS/  ← ejemplos resueltos paso a paso
    ├── examen_22_23.md
    ├── examen_2024_manana.md
    └── examen_2024_tarde.md
```

## Recordatorio de los puntos críticos

1. **Cada uno trabaja en su rama** (`examen/alejandro` y `examen/pablo`). NO os sincronicéis durante el examen.

2. **La VM ya debe estar corriendo** con gunicorn activo en `0.0.0.0:8000` y postgres también activo. Si no:
   ```bash
   ssh si2@localhost -p 12022    # password: si2
   sudo systemctl start postgresql gunicorn
   ```

3. **El navegador del PC accede a la VM** en `http://localhost:18000/visaApp/...` (port-forward 18000→8000).

4. **Los enunciados están en JSF/JSP** (lenguaje antiguo de la asignatura). Vosotros usáis Django. Mira `CHEATSHEETS/mapeo_jsf_a_django.md` para traducir.

5. **No os equivoquéis con la entidad**: si el examen dice `voto`, no asumáis `pago`. Lee literal.

6. **La entrega es un `.tar.gz`**, NO se entrega por git. Mira `CHEATSHEETS/formato_entrega.md`.

7. **El nombre del fichero `.tar.gz`** es crítico: `SI2EXTxPyyApellido1Apellido2Nombre.tar.gz`. **Mira el enunciado para saber `x` (turno) e `yy` (pareja).**

## Si Claude falla / se queda colgado

Abre una nueva sesión Claude Code y vuelve a pegar `PRIMER_MENSAJE.md`. No pierdas tiempo peleándote con una sesión rota.

## Suerte
