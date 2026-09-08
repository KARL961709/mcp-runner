# RUNBOOK — Calibración en el artefacto MLOps CompPP Reenganche (`cppibkren`)

Deja las dos tablas del artefacto con la calibración cableada. **El esquema de destino es automático** (lo fija la plataforma MLOps por config, como Hipotecario): `inference.sql` es `SELECT`-only, sin `INSERT` ni esquema hardcodeado.
- **`ds`** (input) — features + `trf_tipo_ingreso_dep` (segmento, interno), `trf_macro01` (=f_t), `trf_macro02` (=x, macro transformada).
- **`scr`** (output) — `grupo_calibracion` **vacío** · `prob_modelo_cal` (PIT λ=1) · `prob_modelo_cal_smacro` (λ=0, sin macro) · `trf_macro01=f_t` · `trf_macro02=x`.

Coeficientes = `entrega_ree/outputs_v5`. Referencia verificada: `mcp-runner/proyectos/ree_scoring/sql_prod/71_scr_cal_202608.sql` (reproduce la vigente a 1e-10). Aritmética del `inference.py` vs `71`: **max_dif 0.0** (test local).

---

## Qué cambió en el artefacto

| Archivo | Cambio |
|---|---|
| `s3/models/calibracion_ree.json` | **nuevo** — coeficientes (BetaCal a/b/m, δ_seg, δ₀, ρ, λ). Va en `models/` para que `load_calib` lo lea desde `DIR_MODELS`. |
| `s3/scripts/inference.py` | `load_calib` + `postprocessing_fn` (PIT+TTC) + `output_fn` (llena calibración) + `main`. |
| `s3/queries/inference.sql` | **`SELECT`-only** (sin `INSERT`/esquema; la plataforma crea la tabla) · +3 columnas + CTEs `cal_meses/ipc/mac/ft/cls_ing` (macro desde `t_mst_bcrp_rsk`, segmento desde `ds_rtd_rskvol_cas_ingr_ir`). |
| `s3/queries/testing_out.sql` | contrato con columnas de calibración. |

---

## Orden de ejecución

1. **Validar (Fase 4)** — por el puente mcp-runner:
   ```
   .\Go.ps1 -SqlDir proyectos\ppree\sql_val -Only V3_frontera_scoring,V4_cola_densidad,V5_valida_ft,V6_valida_segmento,D5_describe_ds,D6_describe_scr
   ```
   - **V3/V4**: frontera de scoring (mes tope) y densidad de la cola. Medido: mes tope = **202608** (binding = pd_v5).
   - **V5** gate: `max_abs_dif` entre `f_t` recomputado y la vigente. Medido: **2.28e-7** (inmaterial, <2e-8 en PD; precisión de almacenamiento).
   - **V6**: `pct_dep` estable y la CTE ejecuta. Medido: ~3% en el universo `ds_rtd`.
   - **D5/D6** (`DESCRIBE`): esquema del `ds` y tipos reales de la tabla calibrada.
2. **Construir el `ds`** — la plataforma MLOps corre `inference.sql` (`SELECT`-only) y **crea la tabla en el esquema configurado** (automático).
3. **Scorear** — el processing job de SageMaker corre `inference.py` (pkl → calibración → `scr`).
4. **Validar el `scr`** — `testing_in.sql` / `testing_out.sql`, y reconciliar `prob_modelo_cal` contra `d_perm_aws.scr_stk_ree_pp_cal_202607` (debe dar ~1e-9).
5. **Gobierno** — ✅ HECHO: `Diccionario_de_Datos` (Dataset +3 filas; score con descripciones/tipos corregidos, `trf_macro02` a decimal) y `Matriz_de_Fuentes` (`ds_rtd_rskvol_cas_ingr_ir` + `t_mst_bcrp_rsk` en ambas hojas; macro BPE reemplazada).

---

## Validación (3 agentes, 2026-09)

Núcleo numérico **CORRECTO y fiel a `71` bit a bit** en los tres frentes (inference.py, inference.sql, cross-file). Sin bugs ALTA. Confirmado: aritmética PIT/TTC = 71; INSERT↔SELECT 57=57 sin desalineos; `f_t` byte a byte; joins sin fan-out; coeficientes dígito a dígito vs entrega/71; sin referencias colgadas (`trf_f_t`/`trf_ipc_x`). Fixes LOW aplicados: `f_t_col` desde el JSON, comentarios corregidos, tipos `ds` homologados a `double`, anotación BCRP precisada, path de referencia corregido.

## Decisiones abiertas (owner) — MEDIA

- **`info_model.columns_output`**: hoy `["puntuacion"]` (score crudo). Para modelo calibrado debería ser `["puntuacion_cal"]` **y** recalcular `upper_bounds` sobre la distribución calibrada. Decisión del owner + cortes calibrados.
- **Ruta del `ds` en el job**: el `ProcessingInput` del ipynb (TODO 4) debe apuntar a la ruta donde la plataforma crea el `ds`. Como el `ds` se crea del `SELECT`, las 3 columnas nuevas viajan solas (no hay rename manual que las pierda).
- **`ft` LEFT vs INNER**: `inference.sql` usa `LEFT JOIN ft` (conserva clientes aunque falte `f_t`) vs el `INNER` de `71`. Deliberado; en meses válidos no dispara. Si se prefiere no emitir PD NaN, cambiar a INNER.

## Pendientes de correctitud

- **pkl == pd stored**: única incógnita de correctitud. Se cierra comparando `scr.prob_modelo` (salida del pkl) vs `v5.pd_comppp_reen_itc` cuando exista el `scr`, o por rescore Python del `.pkl`.
- **Frontera de scoring**: mes tope = `MIN(pd_v5, segmento+1, macro+6)` = **202608** (binding pd_v5); macro alcanza a 202612.

## Notas del `f_t` (macro)

- Fuente: `e_perm_aws.t_mst_bcrp_rsk.porc_ipc` (ticker PN01271PM, IPC Lima var. mensual). Verificado == parquet de calibración, `max_dif 0.0`.
- `f_t(T)` usa `AVG(porc_ipc)` de T-10 a T-5 → sin forecasting; calendario propio (no las filas del IPC). Centro (+0.19111262350586136) y cap ([-1.1308495593693428, 0.7656842281878757]) **congelados** de la calibración.
