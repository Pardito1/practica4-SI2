# Primer mensaje a pegar al iniciar la sesión Claude Code

> Este es el texto que **copias y pegas TAL CUAL** como primer mensaje de tu sesión Claude Code el día del examen, ANTES de hacer ninguna otra cosa. Sustituye `[TU_NOMBRE]` y `[TU_RAMA]` al final.

---

# Contexto

Soy estudiante de SI2 (3º Ing. Informática, EPS-UAM) y estoy haciendo el **examen final de prácticas**. El profesor permite el uso de Claude Code. Trabajo en el repo `Pardito1/practica4-si2` y mi rama es `[TU_RAMA]` (ya creada desde `main`). Mi compañero hace el examen en otra sesión y otra rama; **no nos sincronizamos**, cada uno entrega lo suyo.

## Material disponible en el repo (todo en `ExamenSI2Pract/`)

Carpetas con MIS prácticas entregadas (con código y memoria PDF):

- **`ExamenSI2Pract/SI2P1_2311_AlejandroPablo/SI2-P1-entrega/`** — P1
  - `Memoria_SI2_P1_final.pdf`
  - `P1-base/` — app Django principal de pagos (modelo `Pago` + `Tarjeta`, vistas, plantillas, `pagoDB.py` con queries ORM y raw)
  - `P1-ws-backend/` — REST API backend (DRF, `serializers.py`)
  - `P1-ws-frontend/` — frontend que consume el WS REST
- **`ExamenSI2Pract/SI2P2_2311_AlejandroPablo/SI2P2_2311_AlejandroPablo/`** — P2
  - `Memoria_P2_SI2.pdf`
  - `P1-rpc-backend/` — JSON-RPC backend (`django-modern-rpc`, `server_mq.py`)
  - `P1-rpc-frontend/` — frontend RPC (con `cliente_mom/client_mq.py`)
- **`ExamenSI2Pract/SI2P3_2311_Parte1/`** — P3 parte 1
  - `prac3.pdf` (enunciado), `presentation3.pdf`
  - `P3-projects.jmx`, `P3_P1-base.jmx` — JMX de pruebas
  - `src/` con copias de P1-base, P1-rpc-backend, P1-rpc-frontend
- **`ExamenSI2Pract/SI2P3_2311_Parte2/src/`** — P3 parte 2 (P1-ws-backend, P1-ws-frontend)
- **`ExamenSI2Pract/SI2P4_2311_AlejandroPablo/SI2P4_2311_AlejandroPablo/`** — P4
  - `MemoriaP4_Final.pdf`, `P4_P1-base.jmx`, `scripts/` (Apache balanceador), `P1-base/`

Enunciados y exámenes pasados:

- `ExamenSI2Pract/prac1.pdf`, `SI2P*/prac*.pdf` — enunciados de las 4 prácticas
- `ExamenSI2Pract/wuolah-free-SI2-practicas-22-23.pdf` — examen 22-23
- `ExamenSI2Pract/wuolah-free-Examen-practicas-si2-2024.pdf` — examen 2024 mañana
- `ExamenSI2Pract/wuolah-free-Examen(grupo tarde)-practicas-SI2-2024.pdf` — examen 2024 tarde

Material pre-construido para que lo uses como referencia:

- `ExamenSI2Pract/EXAMEN_PREP/PROTOCOLO_TRABAJO.md` — flujo de trabajo del examen
- `ExamenSI2Pract/EXAMEN_PREP/CHEATSHEETS/` — referencias rápidas:
  - `vm.md` — acceso SSH a la VM, comandos típicos, gunicorn, postgres
  - `django_patterns.md` — patrón "añadir un campo nuevo" (modelo + migración + form + template + DAO + view)
  - `jmeter.md` — cómo modificar el JMX (CSV, threads, contadores, random, listas)
  - `apache_balancer.md` — sticky session, balancer-manager, ROUTEID, troubleshooting
  - `mapeo_jsf_a_django.md` — los enunciados están en JSF/JSP antiguo, equivalencia a Django
  - `formato_entrega.md` — estructura del `.tar.gz`, naming, qué incluir
- `ExamenSI2Pract/EXAMEN_PREP/PLANTILLAS/` — esqueletos de Ejercicio1.txt, Ejercicio2.txt, Ejercicio3.txt y `crear_entrega.sh`
- `ExamenSI2Pract/EXAMEN_PREP/SOLUCIONES_EXAMENES_PASADOS/` — análisis de los 3 exámenes anteriores resueltos paso a paso (22-23, 2024 mañana, 2024 tarde)

## Mi entorno físico

- **PC del lab**: aquí estás tú (Claude Code) y aquí está el repo clonado.
- **VM1**: corre en VirtualBox en este mismo PC. Acceso por **SSH a `localhost:12022`** con usuario `si2` y password `si2`. La contraseña sudo dentro de la VM también es `si2`.
- **Red de la VM**: NAT (`enp0s3` con `10.0.2.15`) + Internal Network opcional (`enp0s8` con `192.168.56.11`).
- **Puertos forwarded**: host:18000 → guest:8000 (web), host:12022 → guest:22 (SSH).
- **Servicios en la VM**:
  - PostgreSQL **activo**, BD `si2db`, usuario `alumnodb`/`alumnodb`.
  - **Gunicorn como servicio systemd** (`sudo systemctl status gunicorn`), bind `0.0.0.0:8000`, sirve `~/P1base/visaSite/wsgi.py:application`.
  - Apache **deshabilitado** por defecto (se activa a mano si hace falta).
- **Código P1-base en la VM**: en `/home/si2/P1base/`. El campo `instancia` ya está añadido al modelo (de la P4) y `env` apunta a `127.0.0.1`. Si necesitas un código limpio sin la mod de P4, copia desde el repo: `ExamenSI2Pract/SI2P1_2311_AlejandroPablo/SI2-P1-entrega/P1-base/`.

## Cómo quiero que trabajes

1. **Sé minucioso**: yo soy el que ejecuta. Tú das instrucciones paso a paso. Cuando me digas "ejecuta esto", deja claro **dónde** (terminal del PC del lab vs SSH dentro de la VM) y **qué directorio**.
2. **Code blocks marcados** con `[VM]` o `[HOST]` al inicio para no confundirme. Ejemplo:
   ```
   [VM]  cd ~/P1base && sudo systemctl restart gunicorn
   [HOST] cd ~/repo && git status
   ```
3. **Pega el código completo del fichero** cuando me pidas modificarlo, no solo el diff. Yo lo copio entero.
4. **Pregunta antes de asumir**: si el enunciado del examen es ambiguo, pídeme la captura/texto exacto antes de codificar.
5. **No hagas commits ni pushes automáticamente** salvo que te lo pida explícitamente. El examen lo entregaremos como `.tar.gz` a Moodle, no por git.
6. **Antes de empezar cada ejercicio**, lee:
   - El enunciado del ejercicio (yo te lo pegaré).
   - El cheatsheet relevante en `ExamenSI2Pract/EXAMEN_PREP/CHEATSHEETS/`.
   - La solución del examen pasado más parecido en `SOLUCIONES_EXAMENES_PASADOS/`.
   - El código real de la práctica relacionada en `ExamenSI2Pract/SI2P*/`.

## Cómo voy a comunicarte cada ejercicio

Te pegaré el enunciado del ejercicio (texto + capturas si hace falta). Tú me responderás con:

1. **Resumen** de lo que pide en 2-3 líneas, para asegurar que lo has entendido.
2. **Plan de pasos** numerado.
3. **Comandos / código** paso a paso, con las marcas `[VM]` / `[HOST]`.
4. **Cómo verificar** que cada paso ha funcionado.
5. **Qué meter en `EjercicioN.txt`** cuando aplique.

## Mi primer paso

Cuando termines de leer este briefing, **léete obligatoriamente**:
- `ExamenSI2Pract/EXAMEN_PREP/PROTOCOLO_TRABAJO.md`
- `ExamenSI2Pract/EXAMEN_PREP/CHEATSHEETS/formato_entrega.md`
- `ExamenSI2Pract/EXAMEN_PREP/SOLUCIONES_EXAMENES_PASADOS/` (los 3 ficheros)

Y dime: "Listo, contexto cargado. Mándame el enunciado del primer ejercicio."

---

**Datos personales para la entrega:**
- Nombre: `[TU_NOMBRE]`
- Apellidos: `[TUS_APELLIDOS]`
- Compañero/a: `[NOMBRE_COMPAÑERO]`
- Mi rama de trabajo: `[TU_RAMA]`
- Convención de naming según enunciados pasados: `SI2EXTxPyyApellido1Apellido2Nombre.tar.gz` donde `x`=turno (2311 = 23-mañana?), `yy`=número de pareja.
