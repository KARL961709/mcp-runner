# HANDOFF — para la IA que recibe este git y lo engrana al artifact

Eres la IA en la máquina que **ejecuta** (tiene acceso AWS + corre `.\Go.ps1`). Este documento te dice, paso a paso,
cómo tomar las queries de este proyecto, producir los insumos, y **engranarlos al artifact simulador FEN**. Todo lo que
necesitas está en el git; no dependes de la conversación de origen. Uso: **originación/pricing**, NO ECL/capital.

> LÍMITE MRM (léelo antes de tocar nada): esta metodología está **APTA CON CONDICIONES** (validador) y **NO DESPLEGABLE**
> hasta cerrar gobierno (auditoría). NO etiquetes el resultado como "validado". El `7,31≈7,24` es un **gate QA de anclaje**,
> no validación. Ver [README §5](README.md#5-condiciones-bloqueantes-pendientes).

## Paso 0 — Esquema + LLAVES (evita reventar el CTAS de 14M y un join que miente en silencio)
```
.\Go.ps1 -SqlDir proyectos\fen_overlay\sql_val -Only k00_esquema,k00b_llaves
```
- `k00_esquema.csv`: confirma que existen las columnas de `k01`/`k02`. Si un nombre difiere (p.ej. `tipo_ingreso` o `nodo` en el universo), **corrige `k01`/`k02` antes de seguir** — no adivines.
- `k00b_llaves.csv`: **regla del banco (identidad por código).** `pct_match` (universo→reniec por `key_value`) debe ser ALTO y `ulen_*`=`rlen_*` (mismo formato de llave). Si `pct_match` es bajo o las longitudes difieren, el `key_value` NO calza entre las 2 tablas → **hay que puentear la llave antes del CTAS** (no confíes el join). Es la misma trampa del ubigeo RENIEC crudo, ahora en la llave.

## Paso 1 — Universo 14M FEN (202608) → parquet, y bájalo
```
.\Go.ps1 -SqlDir proyectos\fen_overlay\sql_prod -Only k01_universo_fen_202608 -TimeoutSec 3600 -Bajar
```
- Es un **CTAS** → escribe parquet a `<S3_DATOS>/fen_universo_202608/` (14M filas). `-Bajar` lo sincroniza a `$LocalDatos`.
- Necesita `$S3Datos` y `$LocalDatos` en `config.ps1`. Si el CTAS marca `TIMEOUT` pero SUCCEEDED en Athena, la tabla quedó creada.

## Paso 2 — Agregado del universo para el artifact (pegable)
```
.\Go.ps1 -SqlDir proyectos\fen_overlay\sql_val -Only k02_universo_fen_agg
```
`output\k02_universo_fen_agg.csv` = celdas `grado,r,tipo,pac,n,pd` (~150 filas). **Esta es la vista "Universo" del artifact.**

## Paso 2b — TABLA CONSOLIDADA "con todo" (recomendado para el universo/PEA)
En vez de pegar `s`/IBK+ localmente, se puede consolidar TODO en el banco (una tabla tipo reniec pero con `s` + valor IBK+):
```
.\Go.ps1 -SqlDir proyectos\fen_overlay\sql_prod -Only s01_seed_s_indirecto,s02_seed_ibk_plus
.\Go.ps1 -SqlDir proyectos\fen_overlay\sql_prod -Only s03_fen_overlay_input_202608 -TimeoutSec 3600 -Bajar
.\Go.ps1 -SqlDir proyectos\fen_overlay\sql_val  -Only s04_fen_overlay_agg
```
- `s01`/`s02` siembran `s` (Censo, 1891 distritos) e IBK+ (12 deptos×codmes, con `ibk_centrado`=depto−nac) como tablas del banco.
- `s03` = `disc_model_owner.fen_overlay_input_202608` (por cliente: PD+grado+R_reest+`s`+valor IBK+ centrado+físico) → parquet `-Bajar`.
- `s04` = `output\s04_fen_overlay_agg.csv` = celdas grado×R×tipo×pac×**depto** con `n, pd, s (real), ibk_c`. **Este es el embed del universo con datos reales** → el artifact se mueve con `s` real e IBK+ (no el proxy). Con `s04` NO hace falta el Paso 4 local para el universo.

## Paso 3 — Altas PP (libro vigente + validación)
```
.\Go.ps1 -SqlDir proyectos\fen_valida_rd\sql_val -Only j03_altas_recientes,j01_altas_1a1 -TimeoutSec 1800
```
`j03` = 3 meses recientes (202605–202607, el libro a estresar). `j01` = 81 728 altas maduras (validación PD≈RD). CSVs en `output\`.

## Paso 4 — Pegar los insumos LOCALES (no salen del banco)
Por cada cliente/celda, con la llave del DOMICILIO `ubigeo_dom` (= `ubigeo_inei_nodo`, cascada N1/N2/N3):
- **`s` indirecto:** `elnino_ibk/02_pipeline/out/sectores_agua_distrito.csv` → `s_total` por `ubigeo` (INEI 6 díg). Clampear `s<0 → 0`.
- **IBK+ (recuperación):** `elnino_ibk/02_pipeline/ibk_panel.json` → serie por depto; usar **`IBK+_depto − IBK+_nacional`** (centrado) con `depto = substr(ubigeo_dom,1,2)`. Deptos sin serie → 0 (Tumbes `24` → proxiar con Piura `20`).
- **Cruce por NOMBRE, jamás por ubigeo RENIEC crudo** (mentiría el distrito en ~91% de los casos — por eso usamos `ubigeo_inei_nodo`, ya resuelto por la cascada `Downloads/resumen_cascada_ubigeo.py`).

## Paso 5 — Engranar los DOS artifacts (uno Altas, uno PEA)
Ambos HTML viven en `elnino_ibk/03_deck/` y embeben datos en `var DATA={...}` (celdas) + `var MAPDATA=[...]` (compartido).

**Artifact 1 — Altas:** `estres_fen_pp_cdpp.html` (URL existente `d1098522-...`). Datos = `j03` (libro vigente 202605‑07; muestra la MIGRACIÓN de grados) — valida con `j01`. Trae `rd`.
**Artifact 2 — PEA/Universo:** `estres_fen_pp_universo.html` (ya retitulado; **datos hoy son PLACEHOLDER**). Datos = `k02` (agregado del universo 202608). **NO trae `rd`** (universo sin madurar) — la variante ya quitó el KPI "RD ✓".

Por cada uno:
1. Construye las celdas `{g, r, tipo, pac, n, pd (, rd)}` desde el CSV correspondiente.
2. Pega `s` real y `IBK+` (Paso 4).
3. Reemplaza `var DATA={...}` (regex `/var DATA=\{[\s\S]*?\]\};/` — NO toca `MAPDATA`).
4. **Aplica los fixes obligatorios del motor** (README §5, a los DOS): `ρ→0,0332`; `shift = λ·γ·costa·max(e′,0)`; usar `s` distrital real (no el proxy 0,25/0,65); topear γ; quitar cualquier claim "validado"; carril redistributivo (recomendado).
5. **Verifica render headless** (Chrome `--headless=new --screenshot`, `--user-data-dir` propio, `--virtual-time-budget=9000`).
6. **Publica:** Altas → a la MISMA URL `claude.ai/code/artifact/d1098522-...` (Artifact publish con `url=`). PEA → **nueva URL** (Artifact publish sin `url`, favicon distinto p.ej. 👥) y guarda el URL resultante.

## Paso 6 — Antes de entregar
- NO afirmes "validado/calibrado con precisión". Etiqueta escenarios como "gobierno, no pronóstico".
- Deja constancia de los **2 tests pendientes** (Test A: PD base IPC con-FEN vs sin-FEN; Test B: mean(PD*)=LRA) — si aún no corren, decláralo.
- Reporta el `_resumen` + qué CSV/parquet quedó y dónde.

## Mapa de archivos del git
```
proyectos/fen_overlay/
  README.md                       <- engranaje + datos + fuentes + estado (LEER PRIMERO)
  FUENTES.md                      <- bibliografía verificada (citas + links)
  HANDOFF_IA.md                   <- este archivo
  sql_val/k00_esquema.sql         <- chequeo de columnas
  sql_prod/k01_universo_fen_202608.sql  <- CTAS 14M (-Bajar)
  sql_val/k02_universo_fen_agg.sql      <- agregado para el artifact
proyectos/fen_valida_rd/sql_val/
  j01_altas_1a1.sql               <- altas validación (81 728, RD madura)
  j03_altas_recientes.sql         <- altas 3 meses (202605-202607)
proyectos/ppvc/                   <- calibración PP VC (motor sql_score/30_scr_cal.sql)
proyectos/score_2606/             <- scoreo del universo 14M (README_universo.md)
```
