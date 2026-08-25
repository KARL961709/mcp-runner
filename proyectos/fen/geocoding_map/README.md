# FEN 2026 — geocoding + mapa + dataset por cliente

Scripts que generan el **mapa FEN 2026** (`deck_fen/mapa_fen2026.html`) y el **dataset unificado por cliente**
(`entregables/fen_geocoding/dataset_fen_cliente.parquet`). Aquí vive el "cómo"; los entregables ya están construidos.

> **Rutas hardcodeadas** a `C:/Users/CARLOS/...` (máquina fábrica) y a la carpeta de trabajo
> `Downloads/Data_geo/.../salida/`. Ajustar al reproducir. Los insumos pesados (parquet de geocoding,
> shapefiles CENEPRED, geojson ANA) NO viajan por el repo — ver "Insumos".

## Orden del pipeline

| # | Script | Produce | Lee |
|---|---|---|---|
| 1 | `google_full.py` | `google_cache.sqlite` (rescate Google de X,Y) | cascada + API key (archivo local) |
| 2 | `merge_google.py` | `geocodificado_cascada.parquet` (con gate espacial) | cascada + sqlite |
| 3 | `raster_maps.py` | `fen_max/inund/mm.png` (peligro, 180m) | susc CENEPRED (shapefiles) |
| 4 | `dem_contours.py` | curvas de nivel → `overlays.json` | tiles AWS terrain |
| 5 | `enrich_data.py` | `impacto2017.json`, `noticias.json` | SINPAD xlsx + `07_validacion_noticias` |
| 6 | `build_overlays.py` | `overlays.json` (cuencas/subcuencas/distritos + ficha FEN) | geo ANA + grado_fen_v6 + (5) |
| 7 | `build_ibk_density.py` | `ibk_300/500/1km/loc.png` (densidad) | cascada |
| 8 | `build_ibk_points.py` | `ibk_pts/*.bin` (puntos lote por distrito) | cascada |
| 9 | `dist_flags.py` | `flags_proximidad.parquet` (precisión + distancia a peligro) | cascada + susc CENEPRED |
| 10 | `build_stats.py` | `dist_stats.json` (composición por distrito) | (9) |
| 11 | `build_dataset.py` | **`dataset_fen_cliente.parquet`** (unificado, 59 cols) | (9) + grado_fen_v6 + impacto + noticias |
| 12 | `build_maps_html.py` | `mapa_fen2026_cuencas.html` (servido) | overlays + dist_stats + PNGs |
| 13 | `build_selfcontained.py` | **`mapa_fen2026.html`** (autocontenido, doble clic) | (12) + PNGs + ibk_pts |
| 14 | `valida_flags.py` | validación (invariantes + ground-truth) | (11) |

## Insumos (no versionados)
- **Geocoding base:** `geocodificado_cascada.parquet` (ArcGIS + Google, ~1.74M filas). Es la cartera IBK geocodificada.
- **CENEPRED:** `cenepred/Shape/susc_mmasa_pp.shp`, `susc_inund_pp.shp`, `Riesgo_MMasa_Distritos.shp`.
- **ANA / geo:** `elnino_ibk/01_inputs/geo/` (cuencas, uh_ana_nivel7, peru_dist, distrito_cuenca).
- **Score FEN:** `elnino_ibk/02_pipeline/out/grado_fen_v6.csv` (R0–R5 por ubigeo).
- **SINPAD / noticias:** `elnino_ibk/01_inputs/sinpad/BD_emer_danos_2003_2020.xlsx`, `elnino_ibk/07_validacion_noticias/`.

## Notas de método
- Distancia a peligro = **euclidiana en UTM 18S** (distance transform), no Haversine. Grilla 180m → precisión ~180m (limitada por la fuente CENEPRED 1:1M). Mínimo sensato = contención ("dentro de Muy Alto") / 100m.
- Flags de proximidad son a **susceptibilidad**, no a huella validada → usar SIEMPRE con `R_nivel`.
- Join a la cartera del banco: por `clave`. OJO ubigeo INEI ≠ RENIEC (puente `t_mst_ubigeos_rsk`).
- Diccionario completo de columnas: `entregables/fen_geocoding/DICCIONARIO_dataset_fen_cliente.md`.

**Data interna IBK — repo privado.**
