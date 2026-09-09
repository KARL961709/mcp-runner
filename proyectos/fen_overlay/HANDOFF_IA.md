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

## Paso 5 — Engranar al artifact
Artifact: `elnino_ibk/03_deck/estres_fen_pp_cdpp.html`. Embebe datos en `var DATA={...}` (celdas) y `var MAPDATA=[...]`.
1. Construye el objeto de celdas `{g, r, tipo, pac, n, pd (, rd)}` desde el CSV (para Altas usa `j03`; para Universo usa `k02`).
2. Pega `s` real y `IBK+` (Paso 4).
3. Reemplaza `var DATA={...}` en el HTML (regex `/var DATA=\{[\s\S]*?\]\};/` — NO toca `MAPDATA`).
4. **Aplica los fixes obligatorios del motor** (README §5): `ρ→0,0332`; `shift = λ·γ·costa·max(e′,0)` (piso monotonía); usar el **`s` distrital real** (no el proxy 0,25/0,65); topear γ; quitar el "✓ validado" del KPI (reclasificar a "gate QA de anclaje"); decidir el carril (redistributivo recomendado).
5. **Verifica render headless** (Chrome `--headless=new --screenshot`, `--user-data-dir` propio, `--virtual-time-budget=9000`) — los files fuera del project pane no corren JS.
6. **Republica a la MISMA URL** `claude.ai/code/artifact/d1098522-43de-856c-d4c877462b79` (Artifact publish con `url=`).

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
