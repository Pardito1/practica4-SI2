# PASO 1 — Transferir material del Mac al portátil Xubuntu

> Método: red WiFi local + SSH/rsync. Más rápido que pendrive y más fiable.

## En el Mac (tu equipo actual)

### 1.1 Activar SSH ("Inicio de sesión remoto")

1. **Ajustes del sistema** → **General** → **Compartir** → **Inicio de sesión remoto** → ACTIVAR.
2. Apunta tu **nombre de usuario** del Mac (lo verás abajo: `usuario@equipo.local`).
3. Apunta la **dirección IP** del Mac:

```bash
# Abre Terminal en el Mac y ejecuta:
ipconfig getifaddr en0
# Te dará algo como 192.168.1.42 — apúntala (la llamaremos IP_MAC).
```

### 1.2 Comprobar que la carpeta no tiene espacios problemáticos

La carpeta `Practica 3 SI 2` tiene espacios. No es problema con `rsync` correctamente entrecomillado, pero por si acaso, **no la renombres** ahora — rsync lo gestiona.

---

## En el portátil Xubuntu

### 2.1 Instalar lo mínimo para transferir

Abre Terminal:

```bash
sudo apt update
sudo apt install -y openssh-client rsync
```

### 2.2 Comprobar conectividad con el Mac

```bash
# Sustituye IP_MAC y USUARIO_MAC por los que apuntaste arriba
ping -c 3 IP_MAC
# Si responde, ssh funcionará. Si no, ambos equipos no están en la misma WiFi.
```

### 2.3 Transferir TODO el material (con rsync, reanudable)

```bash
# Crea destino
mkdir -p ~/SI2_examen

# Transferencia (te pedirá la password del Mac la primera vez)
# Sustituye USUARIO_MAC e IP_MAC
rsync -avhP --partial \
  USUARIO_MAC@IP_MAC:"/Users/alejandropardo/Downloads/Practica\ 3\ SI\ 2/" \
  ~/SI2_examen/
```

Notas:
- `-a` preserva permisos y enlaces.
- `-v` verbose (verás qué se está copiando).
- `-h` tamaños legibles.
- `-P` muestra progreso y permite reanudar si se corta.
- Si se corta a mitad, vuelve a ejecutar el mismo comando y sigue donde lo dejó.

Tiempo estimado para 5-7 GB en WiFi normal: 15-30 minutos.

### 2.4 (OPCIONAL) Si rsync no funciona, plan B con scp

```bash
scp -r USUARIO_MAC@IP_MAC:"/Users/alejandropardo/Downloads/Practica\ 3\ SI\ 2" \
   ~/SI2_examen/
```

### 2.5 Comprobar que llegó todo

```bash
cd ~/SI2_examen
ls -la
du -sh *

# Debes ver:
# - apache-jmeter-5.6.3/
# - si2_alumnos-main/
# - practica3-si2/
# - Practica 4 SI 2/
# - ExamenSI2Pract/  (con la carpeta maquinas/ dentro)
# - PDFs (essay_1.pdf, presentation.pdf, etc.)
```

### 2.6 (Recomendado) Mover la VM1 a su sitio definitivo

```bash
mkdir -p ~/VirtualBox\ VMs/
cp -r "~/SI2_examen/ExamenSI2Pract/maquinas/vm1_FINALFINAL" ~/VirtualBox\ VMs/si2vm1
```

Si quieres también las VM2 y VM3 (por si acaso):
```bash
cp -r "~/SI2_examen/ExamenSI2Pract/maquinas/si2vm2" ~/VirtualBox\ VMs/si2vm2
cp -r "~/SI2_examen/ExamenSI2Pract/maquinas/si2vm3" ~/VirtualBox\ VMs/si2vm3
```

---

## Una vez transferido, pasa a `PASO2_INSTALAR_ENTORNO.md`
