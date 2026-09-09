# RUNBOOK ./Go — tabla final "mca con todo" para ALTAS (202605-202607) y PEA (202608)

Todo lo que el `./Go` tiene que producir, en orden. Los CTAS se corren **de a uno** (`-Only`), los agregados por lote.

## Paso 0 — checks (una vez)
```
.\Go.ps1 -SqlDir proyectos\fen_overlay\sql_val -Only k00_esquema,k00b_llaves
```
`k00b` valida que `key_value` calza entre universo/altas y reniec (mismo formato). Si `pct_match` bajo → puentear la llave antes de los CTAS.

## Paso 1 — SEEDS (s + IBK+)  [rápido, read/CTAS chico]
```
.\Go.ps1 -SqlDir proyectos\fen_overlay\sql_prod -Only s01_seed_s_indirecto,s02_seed_ibk_plus
```
- `s01` → `fen_s_indirecto` (s por distrito, Censo; nivel S0-S4 cortes fijos 0,20).
- `s02` → `fen_ibk_plus` (resiliencia IBK+ por depto: **desvío de su PROPIA normal pre-FEN** + gate **Yaku-2023**; **ibk_c_altas/pea** = atenuación *gated*, > 0 SOLO si RESILIENTE = hoy ≥ su normal **Y** recuperó en Yaku; regímenes R/V/F en la columna `regimen`). IBK+ **solo atenúa**. Depto **sin serie propia → peor caso = Junín** (recuperación más lenta) → sin alivio; nunca resiliente sin dato (`coalesce(ibk_c,0)` aguas abajo). Panel hasta Set-26 (12 deptos + nac).

## Paso 2 — CONSOLIDADAS "mca con todo" (CTAS, de a uno, -Bajar)
```
.\Go.ps1 -SqlDir proyectos\fen_overlay\sql_prod -Only s03b_overlay_altas_202605_202607 -TimeoutSec 3600 -Bajar
.\Go.ps1 -SqlDir proyectos\fen_overlay\sql_prod -Only s03_fen_overlay_input_202608     -TimeoutSec 3600 -Bajar
```
Cada cliente con: PD, grado, **R directo / geo / reest**, pac, ubigeo_dom, depto, físico (exp25/50, dist_ma), **s_total + s_nivel**, **IBK+ centrado** (altas usa ibk_c_altas; PEA usa ibk_c_pea) + resiliente.
- `s03b` = ALTAS 202605-202607 (fuente `altas_adm_pp_cdpp_cal`, trae rd12 inmaduro).
- `s03`  = PEA/Universo 202608 (fuente `scr_vcadmbnk_final_hist_rsk_cal_2606_2608`, sin RD).

## Paso 3 — AGREGADOS para el artifact (pegables por _resultados.txt)
```
.\Go.ps1 -SqlDir proyectos\fen_overlay\sql_val -Only s04a_agg_altas_cells,s04b_agg_pea_cells,s04c_agg_mapa_distrito
```
- `s04a` / `s04b` = celdas grado×tipo×**r_dir×r_reest** → n, pd, (rd altas), **s real, ibk_c**. Trae AMBOS R → el toggle Ajuste Geo/Directo se deriva del MISMO dato; s e IBK+ dejan de ser proxy.
- `s04c` = por distrito → n, depto, s, **share_r45 y avg_r (dir y reest)** → el mapa pinta el R de reniec y su recorte R4/R5 CAMBIA con el toggle.

## Paso 4 — TABLA DE ESCENARIOS 202608 (PD estresada por los 6 escenarios de gobierno)
Primero **valida el motor** (barato, segundos) y me pegas las 36 filas — confirmo que cuadran 1‑a‑1 con el simulador:
```
.\Go.ps1 -SqlDir proyectos\fen_overlay\sql_val  -Only k05_check_escenarios
```
Con el visto bueno, creo la tabla:
```
.\Go.ps1 -SqlDir proyectos\fen_overlay\sql_prod -Only s05_escenarios_202608 -TimeoutSec 3600
```
- `s05` → `fen_overlay_escenarios_202608` (**formato largo: 6 filas por cliente**). Por cliente×escenario: `pd_base_facil/cd` + `grado_base_*`, `pd_estres_facil/cd` + `grado_estres_*`, `recorte_duro` (r_reest≥4 = RECHAZO). Motor **idéntico** al simulador (`normal_cdf`/`inverse_normal_cdf` de Trino), R = `r_reest` (Ajuste Geo), pac=0 → sin estrés (PDx=pd0). Escenarios ESC1/ESC2/ESC21/ESC22/ESC31/ESC32 con sus (γ,wF,wA,recup) exactos.

> **Re-corrida (OJO: el esquema de `fen_ibk_plus` cambió en esta versión — ahora trae `normal`, `desvio_altas/pea`, `yaku_claw`, `regimen`).** En una corrida FRESCA no hay nada que hacer (el CTAS crea la tabla). Si la tabla YA existe de una corrida previa, Athena falla el CREATE: primero `DROP TABLE disc_model_owner.fen_ibk_plus` **y vaciar** `<S3_DATOS>/fen_ibk_plus/` (el DROP de una tabla externa no borra el S3; el CREATE falla si el location no está vacío). Misma regla para cualquier tabla que re-crees (s01/s03b/s03/s04*).

## Qué me pegas de vuelta
Los CSV de `output\` de **s04a, s04b, s04c** (agregados chicos). Con eso re-embebo el artifact: celdas reales (toggle vivo), s real, IBK+ por depto, y el mapa por R de reniec. Los parquet de s03/s03b (`-Bajar`) quedan para auditoría 1-a-1.

> Insumo IBK+ (fuente): `elnino_ibk/01_inputs/ibk_plus/ibk_panel_reciente_202609.csv` (panel más reciente). 202607-609 son PROYECCIÓN.
