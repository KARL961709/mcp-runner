# Cruce X,Y de cartera IBK × peligro FEN (CENEPRED) — cómo se calculan las distancias

Cómo obtuvimos el **X,Y** de cada dirección IBK (ArcGIS + Google) y cómo lo **cruzamos con el mapa de
peligro** (inundación + mov. de masas → Unificado) para sacar la **distancia al peligro** y los flags por lote.

> **Solo código** (regla del repo: "el código entra, los datos no salen"). Los shapefiles CENEPRED y el
> parquet de geocoding **NO están aquí** — ver "Insumos externos".

## Scripts
| Script | Qué hace |
|---|---|
| `google_full.py` | Rescate con **Google Geocoding API** de lo que ArcGIS no resolvió. |
| `merge_google.py` | Cascada **ArcGIS + Google** + gate espacial → `lon_final` (X), `lat_final` (Y) WGS84. |
| `raster_maps.py` | Rasteriza los shapefiles CENEPRED a PNG de peligro. |
| **`dist_flags.py`** | **EL CRUCE + LAS DISTANCIAS** (ver abajo). |
| `build_unificado.py` | Genera el Unificado como GeoTIFF + shapefile (inspección QGIS). |

## Cómo se calculan las distancias (`dist_flags.py`)
```
Shapefiles CENEPRED (susc_inund_pp + susc_mmasa_pp, polígonos susceptibilidad 0–4)
   │  (a) RASTERIZAR a grilla 180 m en UTM 18S (EPSG:32718) → Unificado = MAX(inund, mov masa)
   │  (b) GATE Pacífico (borrar lo no-Pacífico)
   ▼
Grilla de peligro (0–4)
   │  (c) distance_transform_edt → CAMPO DE DISTANCIA (metros):
   │        dist_ma = a la celda Muy Alto (clase 4) más cercana
   │        dist_am = a la celda Alto+MuyAlto (clase ≥3) más cercana
   ▼
   │  (d) leer el PARQUET DE CLIENTES (X,Y ArcGIS+Google), reproyectar WGS84→UTM 18S,
   │      ubicar la celda de cada punto y LEER su distancia
   ▼
dist_ma_m, dist_am_m  →  umbralizar  →  flg_ma_100/300/500/1000, flg_am_*, flg_dentro_*
```
Clave del método: rasterizar + campo de distancia hace el cruce **O(1) por punto** y da **metros**
(no solo dentro/fuera). Todo en **UTM 18S** para distancia euclidiana en metros reales.

**Ejemplo:** lote a 250 m del Muy Alto, encima de Alto → `dist_ma_m=250` → `flg_ma_300=1, flg_ma_500=1`,
`flg_ma_100=0`, `flg_dentro_ma=0`, `flg_dentro_alto=1`.

## Insumos externos (NO versionados — son data / pesan >100 MB)
- **Shapefiles CENEPRED** (públicos): `susc_inund_pp.shp`, `susc_mmasa_pp.shp` (~554 MB), `Riesgo_MMasa_Distritos.shp`.
  Fuente: escenario de riesgo FEN de CENEPRED. Copia local en el ZIP `PROYECTO_CRUCE_FEN.zip` (máquina fábrica).
- **Parquet de clientes geocodificado:** `geocodificado_cascada.parquet` (~1.74 M puntos, `lon_final`/`lat_final`).
- **Score para el gate:** `elnino_ibk/02_pipeline/out/grado_fen_v3.csv`.
- **API key de Google:** archivo local, nunca versionada.

## Salida
`flags_proximidad.parquet` (1 fila por lote: `clave, lon_final, lat_final, dist_ma_m, dist_am_m, flg_*`),
que alimenta el dataset maestro `entregables/fen_geocoding/dataset_fen_cliente.parquet` (join por `clave`).

> Precisión topada por CENEPRED 1:1M (±250–500 m) → grilla 180 m, bandas mínimas de 300 m.
> Flags son a **susceptibilidad**, no a huella validada → usar con el grado FEN `R_nivel`.
> **Data interna IBK — repo privado.**
