# hopla

Lanzador tipo Spotlight para GNOME (Wayland), en Python + GTK 4, que se abre con
**Super+Espacio**.

- **Apps**: aplicaciones instaladas.
- **Archivos**: búsqueda con `fd`; Ctrl+Enter abre la carpeta o el proyecto en VS Code.
- **GitHub**: tus repos (vía `gh`), pull requests, issues y notificaciones.
- **Web**: búsquedas en Google, YouTube, Amazon, Spotify, Gmail…

Tab / Shift+Tab cambian de modo conservando el texto, ↑/↓ mueven la selección, Enter abre,
Ctrl+1/2/3 saltan a un modo y Esc (o clic fuera) cierra. Volver a lanzarlo mientras está
abierto lo cierra. La interfaz sigue el idioma del sistema (español o inglés).

## Instalación

```bash
git clone git@github.com:pedroj4567/hopla.git
cd hopla
./install.sh
```

Enlaza `buscador` en `~/.local/bin` (los cambios del repo se aplican sin reinstalar) y asigna
Super+Espacio.

Requisitos: `python3-gi` y GTK 4. Opcionales: `fd-find` (archivos) y `gh` (GitHub).
