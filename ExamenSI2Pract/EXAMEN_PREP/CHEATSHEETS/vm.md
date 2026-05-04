# Cheatsheet — VM1

## Acceso

```bash
[HOST] ssh si2@localhost -p 12022       # password: si2
[VM]   sudo <comando>                    # password sudo: si2
```

## Información del entorno

| Componente | Valor |
|---|---|
| Usuario VM | `si2` (sudo OK con `si2`) |
| OS | Ubuntu 24.04 (`uname -a`) |
| Python | `python3` (3.12) → SIEMPRE usar el venv: `source ~/venv/bin/activate` |
| BD | PostgreSQL 16 — BD `si2db`, user `alumnodb`/`alumnodb` |
| Web server | gunicorn como systemd service `gunicorn.service`, bind `0.0.0.0:8000` |
| Acceso a BD desde Django | `127.0.0.1:5432` (configurado en `~/P1base/env`) |
| Apache | Instalado pero **DESHABILITADO** (`sudo systemctl is-enabled apache2` → disabled) |
| Red | NAT `10.0.2.15` + opcional Internal `192.168.56.11` |

## Port-forwards de VirtualBox (host → guest)

| host | guest | uso |
|---|---|---|
| 12022 | 22 | SSH |
| 15432 | 5432 | PostgreSQL desde host (rara vez necesario) |
| 18000 | 8000 | Web (gunicorn / runserver) — **EL IMPORTANTE** |
| 18080 | 80 | Apache (cuando esté activo) |

⚠️ El puerto del navegador en el host es **18000**, pero dentro de la VM Django escucha en **8000**. La regla de VirtualBox traduce. URL típica:

```
http://localhost:18000/visaApp/tarjeta/
```

## Comandos típicos VM (orden de probable uso)

### Estado de servicios
```bash
[VM] sudo systemctl status gunicorn        # Django via WSGI
[VM] sudo systemctl status postgresql      # BD
[VM] sudo systemctl status apache2         # solo si lo arrancas tú
[VM] ss -tlnp | grep -E ':(8000|18000|5432|80)'   # qué escucha en qué puerto
```

### Reiniciar servicios
```bash
[VM] sudo systemctl restart gunicorn       # tras cambiar settings.py / wsgi.py
[VM] sudo systemctl restart postgresql
[VM] sudo systemctl daemon-reload          # tras tocar /etc/systemd/system/*.service
```

### Logs
```bash
[VM] sudo journalctl -u gunicorn -n 50 --no-pager
[VM] sudo journalctl -u gunicorn -f               # follow en vivo
[VM] sudo tail -f /var/log/postgresql/postgresql-16-main.log
[VM] sudo tail -f /var/log/apache2/error.log      # si apache está arrancado
```

### Django manual (alternativa a gunicorn)
```bash
[VM] sudo systemctl stop gunicorn        # libera el puerto 8000
[VM] cd ~/P1base
[VM] source ~/venv/bin/activate
[VM] python manage.py runserver 0.0.0.0:8000
```
> Acuérdate: para volver a gunicorn → `Ctrl+C` y `sudo systemctl start gunicorn`.

### Migraciones Django
```bash
[VM] cd ~/P1base && source ~/venv/bin/activate
[VM] python manage.py makemigrations visaApp
[VM] python manage.py migrate
[VM] python manage.py showmigrations
```

### Si una migración tras añadir campo NOT NULL pide default:
- Opción 1: añadir `default=...` en el modelo.
- Opción 2: aceptar el prompt y dar valor.
- Opción 3: borrar la tabla y rehacer (drástico):
  ```bash
  [VM] sudo -u postgres psql -d si2db -c "DROP TABLE pago CASCADE;"
  [VM] python manage.py migrate
  ```

### Postgres
```bash
[VM] sudo -u postgres psql -d si2db
si2db=# \dt                                       -- listar tablas
si2db=# \d pago                                   -- describir tabla
si2db=# SELECT * FROM pago LIMIT 5;
si2db=# DELETE FROM pago;
si2db=# ALTER TABLE pago ADD COLUMN concepto VARCHAR(30);
si2db=# \q
```

### Conectar Django a la BD desde shell
```bash
[VM] cd ~/P1base && source ~/venv/bin/activate
[VM] python manage.py shell
>>> from visaApp.models import Pago
>>> Pago.objects.count()
>>> Pago.objects.all().values_list('idComercio', 'instancia')[:5]
```

### Limpiar y poblar
```bash
[VM] sudo -u postgres psql -d si2db -c 'DELETE FROM pago;'
[VM] cd ~/P1base && source ~/venv/bin/activate
[VM] python manage.py populate          # carga tarjetas desde data.csv
```

## Subir ficheros a la VM (desde el HOST)

```bash
[HOST] scp -P 12022 fichero.txt si2@localhost:/home/si2/
[HOST] scp -P 12022 -r carpeta/ si2@localhost:/home/si2/
```

## Bajar ficheros de la VM (al HOST)

```bash
[HOST] scp -P 12022 si2@localhost:/home/si2/fichero.txt ./
[HOST] scp -P 12022 -r si2@localhost:/home/si2/P1base/ ./P1-base-ex/
```

## Activar Apache (si el ejercicio lo pide)

```bash
[VM] sudo systemctl start apache2
[VM] sudo apachectl configtest
[VM] curl -sI http://127.0.0.1:80/   # comprueba que responde
```

> Apache lo desinstalamos del autoarranque para que no estorbe en el examen, pero la config sigue en `/etc/apache2/`. Si el ejercicio lo necesita, arrancarlo es trivial.

## Cosas que NO hay que hacer en la VM

- `sudo apt upgrade` — perderías horas.
- `pip install -U <paquete>` — puede romper compatibilidades.
- `python manage.py migrate --fake-initial` salvo que sepas exactamente por qué.
- Cambiar `settings.py` `ALLOWED_HOSTS` — está en `['*']` y así debe quedarse.
- Tocar el `env` de la BD — apunta a `127.0.0.1` y así debe quedarse.
