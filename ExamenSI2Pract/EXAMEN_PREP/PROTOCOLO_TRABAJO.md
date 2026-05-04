# Protocolo de trabajo durante el examen

## Antes de empezar (5 min)

1. **Comprobar la VM**: en una terminal del PC del lab:
   ```bash
   ssh si2@localhost -p 12022   # password: si2
   sudo systemctl status gunicorn   # esperado: active (running) en 0.0.0.0:8000
   sudo systemctl status postgresql # esperado: active
   curl -sI http://127.0.0.1:8000/visaApp/tarjeta/   # esperado: HTTP/1.1 200 OK
   ```
   Si gunicorn no está activo: `sudo systemctl start gunicorn`.
   Si postgres no está activo: `sudo systemctl start postgresql`.

2. **Crear la rama del examen**: en otra terminal del PC del lab:
   ```bash
   cd ~/practica4-SI2  # o donde tengas el repo
   git fetch origin
   git checkout main
   git pull origin main
   git checkout -b examen/[TU_NOMBRE]   # ej: examen/alejandro
   git push -u origin examen/[TU_NOMBRE]
   ```

3. **Iniciar Claude Code** en el repo y pegar el contenido de `EXAMEN_PREP/PRIMER_MENSAJE.md` como primer mensaje. Esperar a que Claude diga "Listo, contexto cargado".

4. **Crear la carpeta de trabajo del examen**:
   ```bash
   mkdir -p SI2EXTxPyyApellidoNombre   # nombre exacto según enunciado del examen
   cd SI2EXTxPyyApellidoNombre
   ```
   *(Lo crearemos formalmente cuando tengamos el enunciado, que dirá el naming exacto.)*

---

## Durante el examen — para CADA ejercicio

### Paso 1 — Pasar el enunciado a Claude

Copia el texto del enunciado (o si es imagen, hazle una foto y súbela a Claude). Pídele:
> "Aquí tienes el enunciado del Ejercicio N. Léelo, dime qué entiendes que pide y luego espera mi OK antes de empezar."

### Paso 2 — Validar la interpretación

Lee el resumen que te dé Claude. Si algo no encaja con tu lectura del enunciado, **discútelo antes de codificar**. No empieces hasta estar de acuerdo.

### Paso 3 — Aplicar los cambios

Claude te dará comandos y/o código. Por cada bloque:

- **Si es comando `[HOST]`**: copialo y pega en una terminal del PC del lab.
- **Si es comando `[VM]`**: copialo y pega en una terminal SSH conectada a la VM.
- **Si es código de fichero**: abre el fichero, sustituye el contenido tal y como te diga Claude (o pega el bloque en el sitio que te indique). Verifica visualmente.

Después de cada cambio crítico, **avísale del resultado**: "OK", "ha fallado con este error: ...", "el output es: ...".

### Paso 4 — Probar

Cada vez que apliques un grupo de cambios, verifica que la app sigue funcionando:

```bash
[VM]  curl -sI http://127.0.0.1:8000/visaApp/tarjeta/   # debe seguir 200
[VM]  sudo journalctl -u gunicorn -n 30                 # ver logs gunicorn
```

Si Django / gunicorn cascó, **PEGALE EL ERROR A CLAUDE LITERAL**. No interpretes el error; pégalo entero.

### Paso 5 — Generar `EjercicioN.txt`

Pídele a Claude:
> "Genérame el contenido de Ejercicio[N].txt con los resultados que ya tenemos."

Y pégalo en `SI2EXTxPyyApellidoNombre/EjercicioN.txt`.

### Paso 6 — Commit incremental (recomendado)

Cada vez que termines un ejercicio o un punto importante:
```bash
[HOST] cd ~/practica4-SI2
[HOST] git add -A
[HOST] git commit -m "EjercicioN: [resumen]"
[HOST] git push origin examen/[TU_NOMBRE]
```

Esto te da una red de seguridad: si algo se rompe, puedes volver a un commit anterior. **No tiene relación con la entrega final** (que va a Moodle como `.tar.gz`), es solo para tu tranquilidad.

---

## Al finalizar el examen — Empaquetado y entrega

### Paso 1 — Verificar contenido de la carpeta del examen

```bash
[HOST] cd ~/practica4-SI2/SI2EXTxPyyApellidoNombre
[HOST] ls -la
```

Tiene que haber, según los exámenes pasados:
- `Ejercicio1.txt`, `Ejercicio2.txt`, `Ejercicio3.txt`
- `P2.jmx` (modificado, si el examen lo pide)
- `P1-base-ex/` (carpeta con la copia modificada de P1-base, si el examen lo pide)

### Paso 2 — Generar el `.tar.gz` con `crear_entrega.sh`

```bash
[HOST] cd ~/practica4-SI2/SI2EXTxPyyApellidoNombre
[HOST] bash ../ExamenSI2Pract/EXAMEN_PREP/PLANTILLAS/crear_entrega.sh
```

Esto produce `SI2EXTxPyyApellido1Apellido2Nombre.tar.gz` en el padre, listo para subir.

### Paso 3 — Verificar contenido del .tar.gz

```bash
[HOST] tar -tzvf ../SI2EXTxPyyApellido1Apellido2Nombre.tar.gz | head -30
```

Debe mostrar la estructura limpia, sin `__pycache__`, sin `venv/`, etc.

### Paso 4 — Subir a Moodle

Sube el fichero `.tar.gz` en la página de entrega del examen. Verifica que se subió correctamente.

### Paso 5 — Backup en pendrive (red de seguridad)

```bash
[HOST] cp ../SI2EXTxPyyApellido1Apellido2Nombre.tar.gz /media/$USER/PENDRIVE/
```

Por si Moodle falla y tienes que demostrar al profesor que lo entregaste a tiempo.

---

## Reglas de oro

1. **Si Claude se contradice o se equivoca, dile que lea el enunciado otra vez**. Pega de nuevo el texto y los outputs que tengas.
2. **No te confíes de los nombres**: si el examen pide entidad `voto`, no asumas `pago`. Lee literal.
3. **Conserva tu memoria sin tocar**: pase lo que pase, en `~/P1base/` original sigue tu código P1 original. Si el examen pide modificar, hazlo en una **copia** (`P1-base-ex/` u otro nombre que diga el enunciado).
4. **No uses `git push --force` jamás**.
5. **Si Claude tarda mucho, comete errores extraños o se queda colgado**, abre una nueva sesión y pégale el `PRIMER_MENSAJE.md` otra vez. No pierdas tiempo peleándote con una sesión rota.
6. **Mira el reloj**: el examen son ~2 horas. Reparto sugerido: Ej1 = 40 min, Ej2 = 40 min, Ej3 = 30 min, empaquetado y subida = 10 min.

---

## Si algo va mal

- **VM no arranca**: tienes la VM en pendrive como backup. Importarla en VirtualBox (`Machine → Add → seleccionar .vbox`).
- **SSH no conecta**: revisa que VirtualBox tenga el port-forward 12022→22.
- **gunicorn no levanta**: `sudo systemctl status gunicorn -l`, mira el error en `sudo journalctl -u gunicorn -n 50`.
- **postgres da error de conexión**: `sudo systemctl restart postgresql && sudo -u postgres psql -d si2db -c '\dt'`.
- **Migraciones fallan con "table already exists"**: borra la tabla con `DROP TABLE ... CASCADE;` en psql, después `python manage.py migrate`.
- **Te bloqueas con un error y no sabes qué hacer**: copia el error literal y pégaselo a Claude. **No reescribas el error con tus palabras**, eso pierde información.
