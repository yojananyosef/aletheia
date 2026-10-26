# Geometría de mapas

- `ne_110m_land.geojson` y `ne_110m_lakes.geojson`: **Natural Earth**, escala
  1:110 m. Dominio público. <https://www.naturalearthdata.com/>
- `ne_rivers.geojson`: ríos de **Natural Earth 50 m**
  (`ne_50m_rivers_lake_centerlines`; Nilo, Éufrates, Tigris, Jordán, Danubio),
  filtrados al caja del atlas (lon 7–44, lat 23–48) con las polilíneas
  troceadas al salir de la caja. Generado con `tool/build_map_layers.py`.
- `ne_boundaries.geojson`: límites de país de **Natural Earth 110 m**
  (`ne_110m_admin_0_boundary_lines_land`), mismo recorte a la caja del atlas.
- Coordenadas de lugares bíblicos: **OpenBible.info Bible Geocoding**,
  CC BY 4.0. <https://github.com/openbibleinfo/Bible-Geocoding-Data>

La app dibuja los mapas localmente con `CustomPainter`; no hay teselas ni
peticiones de red. La atribución aparece al pie de cada mapa y en `NOTICE.md`.
