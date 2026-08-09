---
inclusion: always
---

# VeloxMD es 100% offline

VeloxMD debe funcionar completamente sin conexión a internet. La app **nunca**
descarga ni consume recursos de red en tiempo de ejecución.

## Reglas

- **No usar `google_fonts`** ni ningún paquete que descargue fuentes en runtime.
  Las tipografías (Inter, Fira Code) están empaquetadas como assets locales en
  `assets/fonts/` y declaradas en `pubspec.yaml`. Referenciarlas por
  `fontFamily` (`'Inter'`, `'FiraCode'`), nunca con descarga remota.
- **No agregar dependencias que hagan peticiones HTTP** para obtener assets,
  datos o recursos al iniciar o durante el uso normal.
- **Assets embebidos**: cualquier recurso nuevo (JS, fuentes, imágenes, CSS)
  debe incluirse como asset local. Ejemplo existente: `assets/mermaid.min.js`
  se extrae a un directorio temporal y se carga vía `file://`, sin CDN.
- **Mermaid**: cargar siempre desde el asset local, jamás desde un CDN.
- Las URLs externas (repositorio, sitio del autor) solo son válidas si se abren
  con `launchUrl` **a petición explícita del usuario** (p. ej. el diálogo
  "Acerca de"); no se consultan automáticamente.

## Al agregar código nuevo

Antes de introducir una dependencia o recurso, verificar que no requiera red.
Si algo necesita un recurso externo, empaquetarlo como asset local en su lugar.
