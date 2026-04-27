# Primer mensaje para Claude Code en el lab

Cuando abras Claude Code (`claude`) desde la carpeta del repo, escribe este mensaje (rellena los datos):

---

Vamos a ejecutar la Práctica 4 de SI2 paso a paso. Lee el CLAUDE.md para el contexto completo.

Datos del lab:
- VM1 (Apache + PostgreSQL + Django:18000): IP=[RELLENAR], usuario=[RELLENAR]
- VM2 (Django:28000): IP=[RELLENAR], usuario=[RELLENAR]
- VM3 (Django:38000): IP=[RELLENAR], usuario=[RELLENAR]
- Contraseña SSH: [RELLENAR]
- PC del lab tiene JMeter en: [RELLENAR o "no instalado"]

Empecemos con el setup: copiar código a las VMs, configurar Apache en VM1, migraciones, y arrancar Django en las 3 VMs. Dame los comandos uno a uno, espera a que te confirme antes de pasar al siguiente.

---

## Notas importantes para el lab

1. **No copies todo de golpe** — escribe los comandos uno a uno en Terminal y pega los resultados a Claude Code para que te guíe.

2. **Abre 4 terminales** en el PC del lab:
   - Terminal 1: Claude Code (en la carpeta del repo)
   - Terminal 2: SSH a VM1 (Django + Apache)
   - Terminal 3: SSH a VM2 (Django)
   - Terminal 4: SSH a VM3 (Django)

3. **Para cada ejercicio**, pide a Claude Code: "Dame los pasos del ejercicio X". Cuando tengas capturas o resultados, dile: "Este es el resultado del ejercicio X: [pega output]" y te dirá qué poner en la memoria.

4. **Capturas de pantalla**: hazlas con la herramienta del PC del lab (normalmente PrintScreen o gnome-screenshot). Las guardarás en la carpeta `capturas/` del repo.

5. **Si algo falla**, pega el error exacto a Claude Code y te ayudará a solucionarlo.

6. **Para JMeter (Ej8)**: JMeter se ejecuta desde el PC del lab, NO desde las VMs. El comando es:
   ```
   /ruta/a/jmeter -n -t P4_P1-base.jmx -Jhost=IP_VM1 -l results.jtl
   ```
   Si JMeter no está instalado en el PC del lab, díselo a Claude Code.
