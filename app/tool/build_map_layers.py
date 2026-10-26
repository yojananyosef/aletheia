#!/usr/bin/env python3
"""Genera las capas de rios y limites para el atlas de Aletheia.

Origen: Natural Earth (dominio publico).
  rios     ne_50m_rivers_lake_centerlines   (geojson/, rama master)
  limites  ne_110m_admin_0_boundary_lines_land (geojson/, rama master)

Ambas se recortan a la caja del atlas  lon 7..44, lat 23..48 y las
polilineas se parten donde salen de la caja (runs) para no inventar
segmentos rectos atravesando el recorte. Los properties se reducen a
{name} (ingles) que la app traduce; nombre null = solo linea, sin texto.
"""
import json
import sys

BOX_LON = (7.0, 44.0)
BOX_LAT = (23.0, 48.0)

RIVER_KEEP = {  # scalerank <= 5 o nombre explicito (Jordán, etc.)
    'Nile', 'Danube', 'Donau', 'Euphrates', 'Al Furat', 'Firat',
    'Tigris', 'Dicle', 'Shatt al Arab', 'Jordan',
}
RIVER_LABELLESS = {  # ramas/variantes que no llevan texto propio
    'Damietta Branch', 'Rosetta Branch', 'Borcea', 'Bratul Chillia',
    'Bratul Sfintu Gheorghe', 'Bratul Sulina',
}
DROP = {  # grandes integralmente ajenos que la caja roza
    'Ob', 'Ertis', 'Irtysh', 'Pechora', 'Volga', 'Sukhona',
    'Severnaya Dvina', 'Niger', 'Senegal', 'Sénégal', 'Vychegda',
    'Ural', 'Kama', 'Daugava',
}


def inside(p):
    lon, lat = p[0], p[1]
    return BOX_LON[0] <= lon <= BOX_LON[1] and BOX_LAT[0] <= lat <= BOX_LAT[1]


def clip_runs(lines):
    """Trocea líneas delimitando a la caja; devuelve runs cortados por hueco."""
    out = []
    for line in lines:
        run = []
        for p in (line or []):
            if inside(p):
                run.append([round(p[0], 5), round(p[1], 5)])
            elif run:
                if len(run) >= 2:
                    out.append(run)
                run = []
        if len(run) >= 2:
            out.append(run)
    return out


def fc(features):
    return {
        'type': 'FeatureCollection',
        'features': [
            {
                'type': 'Feature',
                'properties': {'name': feat['properties'].get('name')},
                'geometry': feat['geometry'],
            }
            for feat in features
        ],
    }


def compact(obj):
    return json.dumps(obj, ensure_ascii=False, separators=(',', ':'))


def main(rivers_path, bounds_path, out_rivers, out_bounds):
    src = json.load(open(rivers_path))
    river_feats = []
    for x in src['features']:
        p = x['properties']
        name = p.get('name')
        if p.get('scalerank', 99) > 5 and name not in {'Jordan'}:
            continue
        if name in DROP or name in RIVER_LABELLESS:
            continue
        if not (name in RIVER_KEEP or name is None):
            continue
        runs = clip_runs(x['geometry']['coordinates'] or [])
        if not runs:
            continue
        geom = (
            {'type': 'LineString', 'coordinates': runs[0]}
            if len(runs) == 1
            else {'type': 'MultiLineString', 'coordinates': runs}
        )
        river_feats.append(
            {'type': 'Feature', 'geometry': geom,
             'properties': {'name': name}}
        )

    src = json.load(open(bounds_path))
    bounds_feats = []
    for x in src['features']:
        g = x['geometry']
        lines = [g['coordinates']] if g['type'] == 'LineString' else g['coordinates']
        runs = clip_runs(lines)
        if not runs:
            continue
        geom = (
            {'type': 'LineString', 'coordinates': runs[0]}
            if len(runs) == 1
            else {'type': 'MultiLineString', 'coordinates': runs}
        )
        bounds_feats.append(
            {'type': 'Feature', 'geometry': geom,
             'properties': {'name': None}}
        )

    with open(out_rivers, 'w') as fh:
        fh.write(compact(fc(river_feats)))
    with open(out_bounds, 'w') as fh:
        fh.write(compact(fc(bounds_feats)))
    print('rivers:', len(river_feats), 'features')
    print('bounds:', len(bounds_feats), 'features')


if __name__ == '__main__':
    if len(sys.argv) != 5:
        print(__doc__)
        sys.exit(2)
    main(*sys.argv[1:])
