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
- `s02` → `fen_ibk_plus` (IBK+ centrado por depto: **ibk_c_altas** = avg 202605-207, **ibk_c_pea** = 202608; panel más reciente hasta Set-26). IBK+ **solo atenúa**; resiliente = centrado > 0.

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

## Qué me pegas de vuelta
Los CSV de `output\` de **s04a, s04b, s04c** (agregados chicos). Con eso re-embebo el artifact: celdas reales (toggle vivo), s real, IBK+ por depto, y el mapa por R de reniec. Los parquet de s03/s03b (`-Bajar`) quedan para auditoría 1-a-1.

> Insumo IBK+ (fuente): `elnino_ibk/01_inputs/ibk_plus/ibk_panel_reciente_202609.csv` (panel más reciente). 202607-609 son PROYECCIÓN.
