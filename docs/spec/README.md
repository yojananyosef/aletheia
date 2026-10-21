# Spec — Aletheia en Flutter

Documentos:

1. **[01-inventario-funcional.md](01-inventario-funcional.md)** — inventario completo de funciones con prioridad (P0–P3), evidencia y criterio de aceptación del MVP.
2. **[02-arquitectura-flutter.md](02-arquitectura-flutter.md)** — decisiones de stack, módulos, modelo del workspace, motor del lector, milestones M0–M6.
3. **[03-contrato-catalogo.md](03-contrato-catalogo.md)** — modelo de dominio, API REST `/v1`, almacenamiento, ingesta y catálogo semilla de dominio público.
4. **[04-mejoras-diseno.md](04-mejoras-diseno.md)** — repaso visual del clon contra el original: evidencia medida y lista priorizada de mejoras de acabado (paquetes A–E).
5. **[05-fuentes-contenido.md](05-fuentes-contenido.md)** — fuentes, licencias, atribución y proceso de ingesta de la profundidad de contenido y los mapas.

## Resumen ejecutivo

- **Alcance:** paridad funcional/UX con la app web de referencia (vistas, flujos y mecánicas), con **contenido propio** (dominio público) servido por un **catálogo desacoplado** y empaquetado para funcionar sin servicio.
- **Núcleo del MVP (P0):** shell + omnibox (parser de referencias + búsqueda) · workspace de tiles/pestañas persistente · lector de Biblia/libros (versículos, notas al pie, cross-refs, Contents, History, Reference box, Change book) · Library desde el catálogo · búsqueda All/Bible/Books · Settings mínimos + i18n ES/EN.
- **Diferencias deliberadas:** sin contenido licenciado (ESV/NIV/RVR60/…), sin formatos propietarios, sin marcas/activos originales, sin tienda real ni telemetría; el lector del original usa canvas propietario (Sinai) → el clon usará widgets nativos (accesibles) con modo paginado equivalente.
- **Plugins opcionales (IA):** Study Assistant ✅ (M6.4, con el motor tras `StudyAssistantEngine`; sin proveedor conectado muestra el estado «sin sesión» del original) y Synopsis (5.5, P3) siguen tras una interfaz de proveedor intercambiable; ninguno usa datos de la cuenta.
- **Estado:** **M0–M6 completados** (shell y workspace, lector, catálogo + Library + Search, formatos/vista/ajustes, Notes, herramientas M5, M6 completo — Ideas/Información, Marcadores, Herramientas, Estudio guiado, Planes de lectura, Inicio y Asistente), más los paquetes de acabado **A–E**, la **autonomía local** (contenido + índice FTS5 empaquetados), la **búsqueda de estudio** (`NEAR`, `BEFORE` local, campos, filtros, facetas, agrupación, teclados griego/hebreo y ámbitos Morfología/Mapas/Multimedia) y la **profundidad de contenido** (ASV/BLL/SBLM/BES/VBL, TAHOT/TAGNT, léxico Strong, comentario, diccionario y TSK), los **mapas bíblicos offline** (18 mapas en Factbook y comentario) y la **paridad 1** (Link sets A–F, Tienda local, pantalla completa por panel y tema claro/oscuro/sistema). Suite completa de pruebas unitarias/widget + integración en Linux (`persistence_test`, `catalog_flow_test`, `offline_catalog_test`); servicio **52/52**.
- **Siguiente paso:** completar las herramientas restantes de la web (Atlas, Cursos, Documentos, Medios, Favoritos y Explorador de Salmos), validar Windows/macOS y abordar mejoras opcionales (exportación/impresión, más contenido, accesibilidad, rendimiento medido) y, opcionalmente, el plugin Synopsis (§5.5) y un proveedor de IA real para el Asistente.
