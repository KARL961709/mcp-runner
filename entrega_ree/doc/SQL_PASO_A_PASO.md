# Cadena SQL paso a paso — Comportamental PP Reenganche

**Entregable de la calibración PD Reenganche (SBS / IFRS 9).**
Documenta la construcción del insumo de calibración desde las fuentes madre hasta los cuatro
parquets que consume Fase 2, script por script.

- **Código documentado:** `C:\Users\CARLOS\mcp-runner\proyectos\ppree\sql_prod` (16 CTAS de
  producción + 20 `DROP` de reset) y `C:\Users\CARLOS\mcp-runner\proyectos\ppree\sql_val`
  (11 consultas de QA).
- **Bitácora de evidencia:** `config/ACUERDOS.md` (H = hecho medido, A = decisión firmada).
  Toda cifra de este documento lleva su referencia `Hnn` / `Ann` o su archivo de origen.
- **Corte de datos (pin as-of):** `max_codmes_dato = 202606` (H22, A10).

**Regla de lectura.** Los nombres de tabla y columna de este documento fueron *leídos* de los
`.sql`, no reconstruidos de memoria. Las cifras vienen de `ACUERDOS.md` o de
`outputs_v5/json/data_quality.json`. Donde algo **no** está medido, se dice explícitamente en la
§11 en vez de racionalizarlo.

---

## 1. Convenciones de la cadena

| Concepto | Definición operativa | Dónde se fija |
|---|---|---|
| `codmes_mrm` | **t0** — el mes de la foto sobre la que se decide. Es el eje temporal de TODA la cadena. | `10_po.sql` L19 |
| `codmes_scr` | Mes del archivo de scoring = `codmes_mrm + 1`. | `10_po.sql` L20 |
| `id_value` | Llave hash del cliente, 64 caracteres. Se renombra `key_value` sólo en los exports. | `10_po.sql` L22 |
| `tip_doc` | Tipo de documento. Dominio `'1'`/`'3'`, longitud 1, sin padding (H91). | todas |
| **Grano canónico** | `(codmes_mrm, tip_doc, id_value)`. Verificado sin duplicados en las 14 tablas (H81, H96). | `sql_val/v1`, `v7`, `v11` |
| Prefijo | Todas las tablas viven en `disc_model_owner` y se llaman `ds_stk_ree_pp_<paso>`. | — |
| Aritmética de meses | **Siempre por calendario** (`DATE_ADD('month', k, DATE_PARSE(codmes,'%Y%m'))`). Nunca resta entera sobre `YYYYMM`. | O6/P1, aplicado en 10, 25, 30a/b, 35, 40, 60, 70 |

Ninguna tabla usa `;` y cada archivo contiene **un solo** `CREATE TABLE AS` — restricción de
Athena, documentada en `mcp-runner/CLAUDE.md`. La cadena está **materializada**: Trino inlinea los
CTE, así que un mega-query recomputaría cada rama tantas veces como se la referencie.

---

## 2. Diagrama de dependencias

Flechas = "alimenta a". Las fuentes madre (esquema externo) van a la izquierda del `»`.

```
FUENTES MADRE                                          CADENA disc_model_owner.ds_stk_ree_pp_*
─────────────────────────────────────────────────      ────────────────────────────────────────

d_perm_aws.ds_compppibk_rsk        (≤202012) ─┐
e_perm_aws.scr_compppibk_rsk       (≥202101) ─┴──»  10_po ──┬──────────────────────────────┐
                                                            │                              │
d_perm_aws.t_mrm_mongest_altas_pp_marcas_maa_tmp ─┐         │                              │
e_perm_aws.t_mst_ctaibk_rsk        (puente CIF)  ─┴──»  11_marca ─────────────┐            │
                                                            │                 │            │
e_perm_aws.t_rsk_bkp_cierre_mensual ─┬──────────────»  20_dm ──┬──────────────┤            │
  (prod 06%, ≠Cre.Efec.GH, HPC)      │                         │              │            │
                                     ├──────────────»  21_gh ──┼──────────────┤            │
  (prod='06 Cred efectivo',          │                         │              │            │
   subprod='Cre.Efec.GH')            │                         │              │            │
                                     ├──────────────»  22_rf ──┼──────────────┤            │
  (prod 08%, subprod 06%, HPC)       │                         │              │            │
                                     └──────────────»  26_meses ──────────────┤            │
  (mismo scope que 20_dm, GROUP BY mes)                        │              │            │
                                                               │              │            │
e_perm_aws.t_sco_maestro_cl_rsk  ─┐                            │              │            │
e_perm_aws.t_mst_ctaibk_rsk      ─┴──────────────────»  23_cst ─┤             │            │
                                                               │              │            │
e_perm_aws.t_colaboradores_gdh_rsk ──────────────────»  24_colab ─────────────┤            │
                                                                              │            │
d_perm_aws.t_fact_report_rcc_rsk   (201812) ─┐                                │            │
e_perm_aws.t_fact_report_rcc_rsk (201901+) ─┴────────»  25_sf ────────────────┤            │
                                                                              │            │
                                                    10_po + 20_dm + 22_rf + 23_cst         │
                                                          │                                │
                                                          ├──»  30_fut_a  (k = 1..6)  ─┐   │
                                                          └──»  30_fut_b  (k = 7..12) ─┤   │
                                                                                       │   │
                                                                     35_target  «──────┘   │
                                                                          │                │
e_perm_aws.ds_rtd_rskvol_cas_ingr_ir ─┐                                   │                │
e_perm_aws.t_rsk_cta_sueldo          ─┴── + 10_po ──»  40_drivers ────────┤                │
                                                                          │                │
disc_riesgos.t_b39918_scr_stockpp_itc_reen_reprocesov4 ─┐                  │                │
                                          + 10_po ─────┴──»  50_pd ───────┤                │
                                                                          │                │
                          ┌───────────────────────────────────────────────┴────────────────┘
                          │
                          ▼
                   90_gate/60_filtros   (lee 10_po, 11_marca, 20_dm, 21_gh, 22_rf,
                          │              23_cst, 24_colab, 25_sf, 26_meses)
                          ▼
                   90_gate/70_cal  →  disc_model_owner.ds_stk_ree_pp_cal
                          │            (lee 60_filtros, 35_target, 40_drivers, 50_pd, 26_meses)
                          │
        ┌─────────────────┼─────────────────┬─────────────────┐
        ▼                 ▼                 ▼                 ▼
  90_export_master  91_export_clean  92_export_dirty  93_export_macro
   px_master          px_clean         px_dirty         px_macro
   (S3 → parquet)     (S3 → parquet)   (S3 → parquet)   (S3 → parquet)
```

**Orden de ejecución obligatorio** (un CTAS por corrida; el runner no corta el `foreach` ante un
error, así que **la causa raíz es siempre el primer error** — `mcp-runner/CLAUDE.md`):

```
10_po → 11_marca → 20_dm → 21_gh → 22_rf → 23_cst → 24_colab → 25_sf → 26_meses
      → 30_fut_a → 30_fut_b → 35_target → 40_drivers → 50_pd
      → 90_gate/60_filtros → 90_gate/70_cal
      → 90_gate/90_export_master → 91_export_clean → 92_export_dirty → 93_export_macro
```

`30_fut_a` y `30_fut_b` sólo necesitan `10_po`, `20_dm`, `22_rf` y `23_cst`; `40_drivers` y
`50_pd` sólo `10_po`. Pueden correrse en cualquier orden entre sí.

---

## 3. Fuentes madre — inventario

| Esquema.tabla | Rol en la cadena | Consumida por | Cobertura medida |
|---|---|---|---|
| `d_perm_aws.ds_compppibk_rsk` | Archivo de scoring PP histórico (tramo ≤202012) → universo | `10_po` | 201902–202012 (ventana leída) |
| `e_perm_aws.scr_compppibk_rsk` | Archivo de scoring PP vigente (tramo ≥202101) → universo | `10_po` | 202101–202607 (ventana leída) |
| `d_perm_aws.t_mrm_mongest_altas_pp_marcas_maa_tmp` | **Marca de reenganche** (`subproducto = '1.REENGANCHE'`) → define el perímetro | `11_marca` | 119.257 filas, 201901–202604 (H17) |
| `e_perm_aws.t_mst_ctaibk_rsk` | Puente CIF: `cod_cuc` → `key_value` / `tip_doc` | `11_marca`, `23_cst` | — |
| `e_perm_aws.t_rsk_bkp_cierre_mensual` | Cierre mensual de cuentas: mora, saldos, producto, `as_of_date` | `20_dm`, `21_gh`, `22_rf`, `26_meses` | 201901–202606 con **hueco en 202107** (H45) |
| `e_perm_aws.t_sco_maestro_cl_rsk` | Ingreso a cobranza judicial (`ingreso_cj_fc`) → castigo | `23_cst` | — |
| `e_perm_aws.t_colaboradores_gdh_rsk` | Padrón de colaboradores (`empresa = 'INTERBANK'`) | `24_colab` | 201903–**202401** (H15) |
| `d_perm_aws.t_fact_report_rcc_rsk` | RCC — mora en el sistema financiero (corte 201812) | `25_sf` | 201812 |
| `e_perm_aws.t_fact_report_rcc_rsk` | RCC — mora en el sistema financiero (201901+) | `25_sf` | 201901–202605 (ventana leída) |
| `e_perm_aws.ds_rtd_rskvol_cas_ingr_ir` | Situación laboral / tipo de ingreso | `40_drivers` | **sin filas antes de 202201** (H16, H87) |
| `e_perm_aws.t_rsk_cta_sueldo` | Flag de cuenta sueldo (`flg_cs_riesgos`) | `40_drivers` | 202101–202606; cobertura 34–45% del perímetro (H90, H93) |
| `disc_riesgos.t_b39918_scr_stockpp_itc_reen_reprocesov4` | **PD del scorecard de reenganche** (`pd_comppp_reen_itc`) | `50_pd` | `codmes_mrm` 202312–202604, 29 meses, 0 nulos (H34) |

---

## 4. Ficha por script — staging

### 4.1 `10_po.sql` — Población objetivo (universo comportamental PP)

| | |
|---|---|
| **Crea** | `disc_model_owner.ds_stk_ree_pp_10_po` |
| **Lee** | `d_perm_aws.ds_compppibk_rsk` (`codmes` 201902–202012) ∪ `e_perm_aws.scr_compppibk_rsk` (`codmes` 202101–202607) |
| **Grano** | `(codmes_mrm, tip_doc, id_value)` — `SELECT DISTINCT` |
| **Filtros** | ventana por fuente (el corte 202012/202101 es el mismo `UNION ALL` que hacía el Recibido, A13); `LENGTH(key_value) = 64` |
| **Emite** | `codmes_mrm`, `codmes_scr`, `tip_doc`, `id_value`, `fuente` (`'d_perm'` / `'e_perm'`) |

El **ancla temporal de toda la cadena** se fija aquí:

```sql
DATE_FORMAT(DATE_ADD('month', -1, DATE_PARSE(codmes, '%Y%m')), '%Y%m') AS codmes_mrm
```

El archivo de scoring del mes `M` describe el stock del mes `M−1`. Por eso `codmes_mrm = codmes_scr − 1`,
por calendario y no por resta entera. La ventana leída 201902–202607 produce **90 cohortes t0:
201901–202606**.

Medido: 11.746.259 filas, 90 meses, 0 duplicados (H81). El `LENGTH(key_value) = 64` **no descarta
ni una fila** — `n_descartadas = 0`, `len_min = len_max = 64` en los 8 años y en las dos fuentes
(H100). Es un control inerte, no un filtro.

Validación cruzada no buscada: `10_po` y `20_dm` dan conteos idénticos año por año, difiriendo
sólo en 2021 (hueco 202107) y en 1 fila en 2026 — **el universo comportamental PP *es* el conjunto
de clientes con cuenta PP en HPC** (H99).

---

### 4.2 `11_marca.sql` — Perímetro reenganche

| | |
|---|---|
| **Crea** | `disc_model_owner.ds_stk_ree_pp_11_marca` |
| **Lee** | `d_perm_aws.t_mrm_mongest_altas_pp_marcas_maa_tmp` a `INNER JOIN` `e_perm_aws.t_mst_ctaibk_rsk` b |
| **Llave de join** | `a.cif_key = b.cod_cuc` (ambos `CAST … AS VARCHAR`) |
| **Grano** | `(id_value, codmes_mrm)` — **sin `tip_doc`** |
| **Filtros** | `a.subproducto = '1.REENGANCHE'`; `LENGTH(b.key_value) = 64` |
| **Emite** | `id_value`, `codmes_mrm` ( = `a.codmes_desembolso`, sin desplazar) |

Dos decisiones no obvias, ambas firmadas:

1. **El perímetro lo define la marca, no el `flg_reenganche` de la v4** (A14). La v4 aporta
   `pd_raw` y nada más; su flag se usa sólo como control cruzado (`falla_scope_vs_v4` en `70_cal`,
   `v5` en QA).
2. **El grano excluye `tip_doc` a propósito** (A17, H38): incluirlo mete fan-out del puente CIF.
   Consecuencia operativa que hay que tener presente al leer los `n`: como el grano del `_cal`
   **sí** tiene `tip_doc`, un cliente con dos documentos en el mismo mes recibe
   `flg_scope_ree = 1` en sus dos filas. Ése es el mecanismo exacto detrás de los deltas del
   funnel medidos en H101 (`gtia_hip` 143 al grano del `_cal` vs 130 al grano sin `tip_doc`).

`codmes_desembolso` se usa **tal cual** como `codmes_mrm` (sin el `−1` de `10_po`). Que las dos
escalas coincidan no es un supuesto: está verificado contra la v4, `n_marca_y_v4` = 15.226/15.226
(2024), 20.013/20.013 (2025), 8.155/8.155 (2026), con `falla_marca_sin_v4 = 0` (H84).

Medido: **119.255 llaves, 88 meses 201901–202604**, delta 0 contra la medición previa `e1b` en
2019–2024 y −1 en 2025 y 2026 (H82).

---

### 4.3 `20_dm.sql` — Cierre mensual, scope PP HPC

| | |
|---|---|
| **Crea** | `disc_model_owner.ds_stk_ree_pp_20_dm` |
| **Lee** | `e_perm_aws.t_rsk_bkp_cierre_mensual` |
| **Grano** | `(codmes, id_value, tip_doc)` — `GROUP BY 1,2,3` sobre filas-cuenta |
| **Filtros** | `codmes` 201901–202606; `prod LIKE '06%'`; `(subprod IS NULL OR subprod <> 'Cre.Efec.GH')`; `aplicativo = 'HPC'` |
| **Emite** | `n_cuentas`, `dm_max`, `flg_alguna_cta_saldo_cero`, `ctrl_saldo_nulo`, `flg_alguna_cta_cuc_nulo`, `as_of_mes`, `flg_asof_igual_codmes` |

Es la tabla que **más decidió el diseño**. Cuatro puntos:

- **La agregación por cuenta vive aquí** (P3). `60_filtros` no vuelve a agregar; sólo joinea al
  grano ya cerrado.
- **Los saldos van sin `COALESCE`**: `vig + ven + jud + castigado = 0` con un `NULL` adentro hace
  que la rama **no** dispare. Envolverlos convertía "saldo desconocido" en "saldo cero" y mandaba
  al bucket 99 a quien no correspondía. `ctrl_saldo_nulo` deja el caso visible. Medido: la
  corrección era **correcta pero inocua** — `n_saldo_nulo = 0` en los 8 años (H85).
- **Expone `codmes` y `as_of_mes` por separado**: el Recibido pinnea unos predicados con
  `as_of_date` y otros con `codmes`. `flg_asof_igual_codmes` mide si difieren; medido
  `falla_asof = 0` en los 8 años (H85, H63).
- El scope excluye `Cre.Efec.GH` (crédito efectivo con garantía hipotecaria) del universo PP; esa
  población se captura aparte en `21_gh` para poder **excluirla explícitamente**, no por omisión.

Medido: 11.634.141 filas (H96). El **hueco 202107** aparece como mes ausente, no como cero filas
(H45).

---

### 4.4 `21_gh.sql` — Garantía hipotecaria en t0

| | |
|---|---|
| **Crea** | `disc_model_owner.ds_stk_ree_pp_21_gh` |
| **Lee** | `e_perm_aws.t_rsk_bkp_cierre_mensual` |
| **Grano** | `(codmes, id_value, tip_doc)` |
| **Filtros** | `codmes` 201901–202606; `prod = '06 Cred efectivo'` **AND** `subprod = 'Cre.Efec.GH'` (igualdad exacta, no `LIKE`) |
| **Emite** | `flg_gtia_hip` = `MAX(CASE WHEN cuc IS NOT NULL THEN 1 ELSE 0 END)` |

Complemento exacto del scope de `20_dm`. Alimenta `filtro_gtia_hip` (CASO 3 → bucket 99).

---

### 4.5 `22_rf.sql` — Refinanciados PP

| | |
|---|---|
| **Crea** | `disc_model_owner.ds_stk_ree_pp_22_rf` |
| **Lee** | `e_perm_aws.t_rsk_bkp_cierre_mensual` |
| **Grano** | `(codmes, id_value, tip_doc)` |
| **Filtros** | `codmes` 201901–202606; `prod LIKE '08%'` AND `subprod LIKE '06%'` AND `aplicativo = 'HPC'` |
| **Emite** | `flg_refi` = `MAX(CASE WHEN cuc IS NOT NULL THEN 1 ELSE 0 END)` |

Tiene **doble uso**, y es importante no confundirlos:
- en **t0** alimenta `filtro_malo_origen` (malo al origen → `flg_clean = 0`);
- en **t0+k** alimenta el evento duro del target (`ev_mK` en `30_fut_a`/`30_fut_b`).

---

### 4.6 `23_cst.sql` — Castigos

| | |
|---|---|
| **Crea** | `disc_model_owner.ds_stk_ree_pp_23_cst` |
| **Lee** | `e_perm_aws.t_sco_maestro_cl_rsk` a `INNER JOIN` `e_perm_aws.t_mst_ctaibk_rsk` c |
| **Llave de join** | `a.cod_cuc = c.cod_cuc` |
| **Grano** | `(codmes, id_value, tip_doc)` — `SELECT DISTINCT` |
| **Filtros** | `a.ingreso_cj_fc IS NOT NULL`; mes truncado en 201901–202606; `LENGTH(c.key_value) = 64` |
| **Emite** | `flg_castigo = 1` (constante sobre las filas que existen) |

`codmes` sale de truncar el **timestamp** `ingreso_cj_fc` a mes:
`DATE_FORMAT(a.ingreso_cj_fc, '%Y%m')`. La llave sale del **puente CIF**, no de la maestra
(`ENR#L171-174`, P9).

Mismo doble uso que `22_rf`: `filtro_malo_origen` en t0 y evento duro del target en t0+k.

*Observación de lectura del código (no medida):* `23_cst` **no filtra por producto**. Un ingreso a
cobranza judicial de cualquier producto del cliente marca `flg_castigo`. Es coherente con la
semántica cliente-céntrica del resto de la cadena (la mora del sistema financiero de `25_sf`
también es cliente-céntrica), pero conviene decirlo en vez de dejarlo implícito.

---

### 4.7 `24_colab.sql` — Colaboradores Interbank

| | |
|---|---|
| **Crea** | `disc_model_owner.ds_stk_ree_pp_24_colab` |
| **Lee** | `e_perm_aws.t_colaboradores_gdh_rsk` |
| **Grano** | `(codmes, id_value, tip_doc)` — `codmes` = `periodo_gdh`, `tip_doc` = `tipdoc` |
| **Filtros** | `empresa = 'INTERBANK'`; `LENGTH(key_value) = 64`. **Sin ventana de mes**: la fuente ya termina en 202401 |
| **Emite** | `flg_colab` = `MAX(CASE WHEN codunicocli IS NOT NULL THEN 1 ELSE 0 END)` |

Dos cosas medidas condicionan su uso:

- La fuente cubre **201903–202401** (H15). Con el lag de 2 meses que aplica `60_filtros`, la rama
  sólo puede disparar para t0 ∈ **[201905, 202403]**; fuera de ahí `filtro_colab = 0` por **falta
  de fuente**, no por medición. Por eso existe la columna `valida_colab` (H51).
- `flg_colab` sale de `codunicocli IS NOT NULL`, **no** de una constante 1 (corrección F2). Una
  fila con `codunicocli` nulo da 0 en el Recibido; una constante 1 sobre-excluía.

---

### 4.8 `25_sf.sql` — Mora en el sistema financiero (RCC)

| | |
|---|---|
| **Crea** | `disc_model_owner.ds_stk_ree_pp_25_sf` |
| **Lee** | `d_perm_aws.t_fact_report_rcc_rsk` (`codmes = 201812`) ∪ `e_perm_aws.t_fact_report_rcc_rsk` (`codmes` 201901–202605) |
| **Grano** | `(codmes, rcc_codmes, id_value, tip_doc)` |
| **Filtros** | `SUBSTR(cod_cuenta_rcc,1,2) = '14'`; `SUBSTR(cod_cuenta_rcc,4,1) IN ('1','3','4','5','6')`; `tipo_credito IN ('01'..'13')` |
| **Emite** | `cond_max = MAX(CAST(condicion AS DOUBLE))`, `codmes`, `rcc_codmes` |

**El scope de cuentas es obligatorio** (`ENR#L206`): sin él la tabla mide otra cosa —
medido factor **468** de diferencia (H55).

El re-estampado temporal es explícito y las dos escalas viajan como columnas separadas:

```sql
DATE_FORMAT(DATE_ADD('month', 1, DATE_PARSE(rcc_codmes, '%Y%m')), '%Y%m') AS codmes
```

`rcc_codmes` es el mes **leído** (= t0 − 1) y `codmes` es el mes al que se **imputa** (= t0). Es
decir: la mora del sistema financiero que se usa para decidir en t0 es la informada en t0−1 — el
lag honesto de disponibilidad (`ENR#L197`, P2). El corte de fuentes 201812 / 201901 corresponde a
H40 y H52; con el `+1`, la unión cubre `codmes` 201901–202606, las 90 cohortes.

Semántica firmada (A11): `condicion` es la mora del **sistema financiero completo** (todas las
entidades del RCC), no la de Interbank. Es exactamente el alcance que la rama "malo en el SF"
quiere, así que la rama es válida — pero se documenta como exclusión de alcance SF, no de mora
IBK. Correlación con la mora IBK a t0: 0,357 / 0,305 (H26).

Centinela: `condicion = 9999` existe en el universo (~137k sobre 716,9M, 0,02%) pero **0 en el
perímetro reenganche** (H89, J2). Ambas cosas son ciertas y no se contradicen.

---

### 4.9 `26_meses.sql` — Meses presentes en el cierre mensual

| | |
|---|---|
| **Crea** | `disc_model_owner.ds_stk_ree_pp_26_meses` |
| **Lee** | `e_perm_aws.t_rsk_bkp_cierre_mensual` (mismo scope exacto que `20_dm`) |
| **Grano** | `codmes` (un registro por mes) |
| **Emite** | `codmes`, `n_filas` |

Tabla de una sola columna útil, y sin embargo necesaria. `falla_foto_t0` es un flag de **MES**, no
de fila (D1, A30). Como flag de fila (`dm.codmes IS NULL`) fundía dos situaciones distintas: el
hueco 202107 de la fuente, y la situación **normal** de un cliente sin cuenta HPC en su t0. Esa
confusión mandaba al bucket 99 a quien no correspondía.

Al derivarse de la fuente, si mañana falta otro mes aparece solo — no hay literal `'202107'` en
ninguna parte del build.

---

### 4.10 `30_fut_a.sql` / `30_fut_b.sql` — Ventana futura k = 1..6 y k = 7..12

| | |
|---|---|
| **Crean** | `ds_stk_ree_pp_30_fut_a` (k=1..6) · `ds_stk_ree_pp_30_fut_b` (k=7..12) |
| **Leen** | `10_po` (expandida) `LEFT JOIN` `20_dm`, `22_rf`, `23_cst` |
| **Llave de join** | `(id_value, tip_doc, codmes = codmes_fut)` en las tres |
| **Grano de salida** | `(codmes_mrm, tip_doc, id_value)` — una fila por cliente-cohorte, 18 columnas por tabla |
| **Emiten** | `dm_mK`, `miss_mK`, `ev_mK` para sus seis `k` |

La expansión es `CROSS JOIN UNNEST(ARRAY[1,...,6])`, y el join a las madres es **por igualdad de
mes** contra `codmes_fut = codmes_mrm + k`. Un *range join* sobre 90 meses no entra en Athena; por
eso la expansión explícita. La partición en dos tablas es por costo, no por semántica.

- `dm_mK` = `dm_max` del mes t0+k.
- `miss_mK` = 1 si el cliente **no tiene fila** en el cierre mensual en t0+k.
- `ev_mK` = `GREATEST(refi_k, cast_k)` — refinanciación **o** castigo en el mes k exacto.

Emitir `ev_mK` **por k** y no por tramo da el target completo en los doce horizontes al mismo
costo. La limitación H10 (evento duro sólo disponible en 03/06/09/12) era de la tabla madre del
build vigente, no de esta reconstrucción.

El `+k` aquí es legítimo: alimenta el **target**, no un filtro (Lente 4 — mirar al futuro para
definir el evento es correcto; mirar al futuro para decidir la elegibilidad es *look-ahead*).

Medido: ambas tablas dan exactamente las mismas 11.746.259 filas que `10_po` — cero fan-out
(H81); `PAR_30a_vs_30b` en `v7` verifica la igualdad de conteos.

---

### 4.11 `35_target.sql` — Los doce horizontes

| | |
|---|---|
| **Crea** | `disc_model_owner.ds_stk_ree_pp_35_target` |
| **Lee** | `30_fut_a` a `LEFT JOIN` `30_fut_b` b sobre `(codmes_mrm, tip_doc, id_value)` |
| **Grano** | `(codmes_mrm, tip_doc, id_value)` |
| **Emite** | 12 `max_dm_NN`, `miss_06`, `miss_12t`, 12 `falla_madurez_NN`, 12 `target_NNm_60`, 12 `target_NNm_30` |

**Definición del target** (por horizonte N ∈ 1..12, umbral U ∈ {30, 60}):

```
target_NNm_U =  NULL                       si falla_madurez_NN = 1
                1                          si max_dm_NN > U  OR  ev_NN = 1
                0                          en otro caso
```

donde `max_dm_NN = GREATEST(COALESCE(dm_m1,0), …, COALESCE(dm_mN,0))` y
`ev_NN = GREATEST(COALESCE(ev_m1,0), …, COALESCE(ev_mN,0))`, es decir:

> **MALO a N meses** = mora estrictamente mayor a U días **en algún mes** de la ventana
> `[t0+1, t0+N]` **OR** refinanciación **OR** castigo en esa ventana.

El default de la calibración es `target_12m_60` (`> 60` días, o sea 61+ dpd, en 12 meses).

**Tres reglas duras**, todas firmadas:

1. **Nunca se lee `dsc_flg_malo_Nm`** (A4). La cascada de 10 ramas de la madre devuelve `'MALO'` →
   0, no `NULL`, para las seis ramas duras (H5), así que leerla sub-cuenta. Se rederiva desde
   columnas base. Contrafactual medido: la diferencia es **7 registros en 5 años** sobre ~86.000,
   `delta_lra ≈ 0,008 pp` — estructural pero inmaterial en este perímetro (H23).
2. **Madurez por calendario**: `falla_madurez_NN = 1 ⟺ codmes_mrm + N > '202606'` (A10, H32). No
   hay literales de mes por horizonte como en `Query_PO_calib.sql#L48-217` (H11): hay un solo pin
   as-of.
3. **Inmaduro → `NULL`, jamás 0.** Medido: `rd12` pasa a `NULL` exactamente desde 202507 (H83).

Se exportan los **doce** `max_dm` y las **doce** `falla_madurez` (G3): antes salían 5 de 12
mientras se emitían 24 targets, así que siete horizontes quedaban sin eje de madurez auditable.

`miss_12t = miss_06 + miss_12` = en cuántos de los 12 meses futuros el cliente **no tiene fila** en
el cierre. **Cuidado: no cuenta el hueco 202107** (H112, A49) — ver §11.

Medido: los diez controles del target en 0 los 90 meses (H83).

---

### 4.12 `40_drivers.sql` — Tipo de ingreso y cuenta sueldo

| | |
|---|---|
| **Crea** | `disc_model_owner.ds_stk_ree_pp_40_drivers` |
| **Lee** | `10_po` (`DISTINCT`) `LEFT JOIN` `e_perm_aws.ds_rtd_rskvol_cas_ingr_ir` `LEFT JOIN` `e_perm_aws.t_rsk_cta_sueldo` |
| **Grano** | `(codmes_mrm, tip_doc, id_value)` |
| **Emite** | `tipo_ingreso`, `tipo_ingreso_dep`, `flg_cs`, `sit_lab_cs_4v`, `sit_lab_cs_5v`, `flg_cs_estado`, `falla_sin_tipo_ingreso`, `falla_sin_cta_sueldo`, `ctrl_fuente_nueva` |

**Anclas temporales** (distintas entre sí, a propósito):

| Driver | Pin | Razón |
|---|---|---|
| tipo de ingreso | `a.periodo = codmes_mrm` | la fuente informa en t0−1, así que el `periodo` etiquetado t0 ya es información disponible (H64) |
| cuenta sueldo | `s.codmes = codmes_mrm − 1` (por calendario) | lag de disponibilidad explícito |

**Dedup de tipo de ingreso** (única política de desempate de toda la cadena; los Recibidos no
tienen ninguna, H12):

```sql
ROW_NUMBER() OVER (PARTITION BY SUBSTR(a.subject_id,3), a.periodo, CAST(a.tip_doc AS VARCHAR)
                   ORDER BY a.p_fecinformacion DESC, a.subject_id ASC) = 1
```

Orden **total** (`ROW_NUMBER`, no `RANK`), con `subject_id` como desempate determinista. Filtro
adicional `numcarga = 1`. La llave se obtiene como `SUBSTR(a.subject_id, 3)` — la fuente antepone
dos caracteres.

**Mapeo `sit_lab` → `tipo_ingreso`:**

```
DEPENDIENTE  ∧ fuente ∉ {INFERIDO, EXPERIAN, SUSALUD, INFERIDO_IND_MVP} → 'DEPENDIENTE'
DEPENDIENTE  ∧ fuente ∈ {INFERIDO, EXPERIAN, SUSALUD, INFERIDO_IND_MVP} → 'MIXTO'
MIXTO                                                                    → 'MIXTO'
resto (y ausencia de fila, vía COALESCE)                                 → 'INDEPENDIENTE'
```

`tipo_ingreso_dep` (el eje de segmentación del BetaCal) colapsa esto a **`DEP`** (sólo
`DEPENDIENTE`) vs **`NO DEP`** (todo lo demás).

**Tres variantes del eje cuenta sueldo, y por qué las tres:**

- `sit_lab_cs_4v` — 4 valores: `DEP_CS`, `DEP_NO_CS`, `MIXTO`, `INDEPENDIENTE`. Es el build
  vigente (`Query_PO_calib#L332-337`).
- `sit_lab_cs_5v` — 5 valores: parte `MIXTO` en `MIX_CS` / `MIX_NO_CS`. Es lo que **especifica**
  el Recibido (`Query Tipo Ingreso - CS#L11-17`, H9). Medido: `MIX_CS` y `MIX_NO_CS` tienen
  bad-rate distinto los 4 años maduros (ratio 1,2–1,6×) y `MIXTO` es el 45–68% del perímetro
  (H28) — o sea, colapsarlos **pierde señal real**.
- `flg_cs_estado` — 3 valores: `CS` / `NO_CS` / `SIN_DATO`. Es el eje **limpio**. La fuente lista
  a **todos** con flag 0/1 (H90), así que la ausencia de fila es un **hueco**, no el dato "no
  tiene". Medido en el perímetro 2024 (n = 15.226): 5.595 con CS = 1, sólo **1.317** con CS = 0
  *medido*, y **8.314 (54,6%)** con CS = 0 *por ausencia de fila* (H93). Y la cobertura oscila
  34,4–45,4% entre años (H94): la composición del driver se mueve con la disponibilidad del dato,
  no con el cliente.

Emitir las tres cuesta lo mismo y evita reconstruir para decidir (A42). La decisión de cuál
consume el modelo **no se toma en el SQL**.

`ctrl_fuente_nueva` marca el régimen de 202604+ (`fuente ∈ {SUSALUD, INFERIDO_IND_MVP}`).

Limitación medida que hay que tener a la vista al leer cualquier resultado por driver:
`pct_sin_tipo_ingreso` = **100% en 2019, 2020 y 2021** (3,97M filas), ≤0,03% desde 2022 ⇒
**`tipo_ingreso_dep` es constante en 36 meses**, el 46% de la ventana de LRA (H87, H16).

---

### 4.13 `50_pd.sql` — PD del scorecard (fuente v4)

| | |
|---|---|
| **Crea** | `disc_model_owner.ds_stk_ree_pp_50_pd` |
| **Lee** | `10_po` po `LEFT JOIN` `disc_riesgos.t_b39918_scr_stockpp_itc_reen_reprocesov4` v |
| **Llave de join** | `v.key_value = po.id_value` AND `v.cod_tip_doc = po.tip_doc` AND **`v.codmes = po.codmes_scr`** |
| **Grano** | `(codmes_mrm, tip_doc, id_value)` |
| **Emite** | `codmes_scr`, `pd_raw`, `score_raw`, `flg_ree_v4`, `falla_cruce_pd`, `falla_pd_rango` |

**El join va contra `codmes_scr`, no contra `codmes_mrm + 1`.** Son el mismo mes, pero escrito así
el invariante queda a la vista y sin una sola operación de fecha — y `v5` en QA lo verifica como
columna (`falla_ancla_scr`), no como argumento.

Que `v4.codmes = codmes_mrm + 1` está medido por **dos** líneas independientes (H33): (a) los 29
conteos de la v4 igualan exacto a los de la madre un mes antes; (b) joineando a igual `codmes`,
`flg_reenganche` coincide en 4 de ~15.000.

Detalles que costaron una corrida fallida: la columna de documento es **`cod_tip_doc`**, no
`tip_doc` (H30, H31).

Polaridad: `falla_cruce_pd = 1` cuando **NO** hay cruce, siguiendo la convención `falla_*` del
build. El Recibido llama `flg_cruce_pd` a la polaridad contraria — está anotado en la cabecera del
propio script para que nadie lo lea al revés.

Cobertura de la fuente: `codmes_mrm` **202312–202604** (29 meses), `n_pd_null = 0`,
`pd ∈ (5e-4; 0,9998)` (H34). **Esto es lo que fija el arranque de la ventana de fit en 202312.**

Cambio de fuente firmado (A9): se pasó de `..._stockpp_itc_reprocesov2` a
`..._stockpp_itc_reen_reprocesov4`. No son el mismo scorecard — `corr(v2,v4) = 0,9096`,
`max|dif| = 0,473` (H106) — por eso A48 obliga a **re-estimar**, no a actualizar.

---

## 5. El gate

### 5.1 `90_gate/60_filtros.sql` — Un `filtro_i` por rama

| | |
|---|---|
| **Crea** | `disc_model_owner.ds_stk_ree_pp_60_filtros` |
| **Lee** | `10_po` po + `LEFT JOIN` a `26_meses`, `11_marca`, `20_dm`, `21_gh`, `22_rf`, `23_cst`, `24_colab`, `25_sf` |
| **Grano** | `(codmes_mrm, tip_doc, id_value)` — **no agrega**: el staging ya viene al grano (P3) |
| **Emite** | `flg_scope_ree`, 6 `filtro_*`, `falla_foto_t0`, `valida_colab`, `ctrl_asof_igual_codmes`, `ctrl_n_cuentas` |

**Todas las columnas son `INTEGER` 0/1, nunca `NULL`.** Verificado en `v11`.

Cada predicado lleva el **pin de mes adentro de la expresión**, no sólo en el `ON` (O4). Es
deliberado: un `LEFT JOIN` que no matchea deja `NULL` en las columnas de la derecha, y sin el pin
adentro el `CASE` no distingue "no matcheó" de "matcheó con valor 0".

| Columna | Predicado | Ancla | Join |
|---|---|---|---|
| `flg_scope_ree` | `mar.id_value IS NOT NULL` | t0 | `11_marca` por `(id_value, codmes_mrm)` — **sin `tip_doc`** |
| `filtro_gtia_hip` | `gh.codmes = codmes_mrm AND gh.flg_gtia_hip = 1` | t0 | `21_gh` por `(id_value, tip_doc, codmes)` |
| `filtro_colab` | `cl.codmes = codmes_mrm − 2 AND cl.flg_colab = 1` | **t0 − 2** | `24_colab` por `(id_value, tip_doc, codmes)` |
| `filtro_malo_sf` | `sf.codmes = codmes_mrm AND sf.cond_max > 60` | t0 (RCC de t0−1 re-estampado) | `25_sf` por `(id_value, tip_doc, codmes)` |
| `filtro_malo_origen` | `(dm.codmes = codmes_mrm AND dm.dm_max > 60)` **OR** `(rf.codmes = codmes_mrm AND rf.flg_refi = 1)` **OR** `(cst.codmes = codmes_mrm AND cst.flg_castigo = 1)` | t0 | `20_dm`, `22_rf`, `23_cst` |
| `filtro_mto_pend` | `dm.as_of_mes = codmes_mrm AND dm.flg_alguna_cta_saldo_cero = 1` | t0 vía `as_of` | `20_dm` |
| `filtro_baja` | `dm.as_of_mes = codmes_mrm AND dm.flg_alguna_cta_cuc_nulo = 1` | t0 vía `as_of` | `20_dm` |
| `falla_foto_t0` | `mes.codmes IS NULL` | t0 | `26_meses` por `codmes` |
| `valida_colab` | `codmes_mrm BETWEEN 201905 AND 202403` | — | ninguno (literal derivado de H15/H51) |

**Disponibilidad de las fuentes en t0 (U3), cerrada por medición:** en **29 de 30** meses la
partición de `t_rsk_bkp_cierre_mensual` del mes M se escribe en los primeros días de M+1, así que
la foto de t0 está disponible al ejecutar en t0+1. `malo_origen`, `mto_pend`, `baja` y `gtia_hip`
**no son CASO 2** y no se relaguean (H78). La medición se hizo sobre la propia fuente, no por
analogía (A35).

`filtro_baja` se construye pero **queda fuera del gate** (A40): `n_cuc_nulo = 0` en los 8 años
sobre el **universo completo** (H86), o sea que es un `filtro_i` que no puede valer 1 en ninguna
parte. Se conserva como columna con su `n = 0` firmado como hecho; sumarlo consagraría un filtro
inerte.

De este archivo se **extrae** `config/caso_filtros.yaml` (A29), no al revés. Dos yamls escritos a
mano divergieron del código, en formas distintas.

---

### 5.2 `90_gate/70_cal.sql` — Ensamblado final

| | |
|---|---|
| **Crea** | `disc_model_owner.ds_stk_ree_pp_cal` ← **la tabla de calibración** |
| **Lee** | `60_filtros` f + `LEFT JOIN` `35_target` t, `40_drivers` d, `50_pd` p, `26_meses` m |
| **Llave de join** | `(codmes_mrm, tip_doc, id_value)` en t/d/p; `codmes` en m |
| **Grano** | `(codmes_mrm, tip_doc, id_value)` — 90 cohortes 201901–202606 |
| **Emite** | todo lo anterior + `flg_clean`, `flg_calib`, `falla_sin_target`, `falla_scope_vs_v4`, `falla_dup`, `valida_scope`, `p_codmes` |

**La ventana no es un `WHERE`.** Entran las 90 cohortes y el recorte lo hace el flag. Esto es lo
que permite que Fase 2 elija su población sin volver a Athena.

Columnas derivadas aquí y no antes:

- **`falla_dup`** — `COUNT(1) OVER (PARTITION BY codmes_mrm, tip_doc, id_value) > 1`. Detecta
  fan-out de cualquiera de los tres `LEFT JOIN`.
- **`falla_madurez_01/03/06/09/12`** — recalculadas **desde `codmes_mrm`**, no traídas por
  `COALESCE` del join a `35_target` (A45). Es función pura del calendario, y el `COALESCE` fundía
  "no cruzó el target" con "cohorte inmadura".
- **`valida_scope`** — `codmes_mrm BETWEEN 201901 AND 202604`. La marca muere en 202604 y el build
  llega a 202606, así que 202605–202606 quedan con `flg_scope_ree = 0` por **falta de fuente**, no
  por medición (A38, P10). Mismo tratamiento que `valida_colab`.
- **`falla_scope_vs_v4`** — control cruzado: `flg_scope_ree = 1` pero el `flg_reenganche` de la v4
  dice lo contrario.
- **`falla_cruce_pd`** viene con `COALESCE(…, 1)` y `falla_pd_rango` con `COALESCE(…, 0)`: si el
  `LEFT JOIN` a `50_pd` no matchea, la ausencia de PD se cuenta como falla, no como cero.

---

## 6. Población objetivo — definición operativa paso a paso

Ésta es la respuesta a *"¿cuál es exactamente la población?"*, en el orden en que el código la
construye. Cada paso indica qué la define y dónde vive.

### Paso 0 — Universo comportamental PP  *(`10_po`)*

> Toda observación `(cliente, tipo de documento, mes)` presente en el archivo de scoring
> comportamental de préstamos personales, con el mes trasladado un período hacia atrás
> (`t0 = codmes_scr − 1`).

Fuentes: `d_perm_aws.ds_compppibk_rsk` (≤202012) ∪ `e_perm_aws.scr_compppibk_rsk` (≥202101).
Ventana: **90 cohortes t0, 201901–202606.** Volumen: **11.746.259** observaciones (H81).

Equivalencia medida: este universo coincide año a año con el conjunto de clientes con cuenta PP en
HPC del cierre mensual (H99).

### Paso 1 — Perímetro reenganche  *(`flg_scope_ree = 1`)*

> De ese universo, las observaciones cuyo cliente tiene **marca de reenganche** en ese mismo mes,
> según `d_perm_aws.t_mrm_mongest_altas_pp_marcas_maa_tmp` con `subproducto = '1.REENGANCHE'`,
> cruzada por el puente CIF `e_perm_aws.t_mst_ctaibk_rsk`.

Lo define **la marca**, no el `flg_reenganche` del scorecard (A14). La marca tiene 119.255 llaves
en 88 meses (201901–202604) (H82); el perímetro construido tiene **119.254 filas**
(`data_quality.json: master_shape`).

Contraste que justifica separar el perímetro: bad-rate reenganche **3,42%** vs resto del stock
**16,97%** — el resto es 2,3× a 5× peor los cuatro años (H53, `caso_filtros.yaml`).

`flg_scope_ree` es **eje propio y NO alimenta `flg_clean`** (A36).

### Paso 2 — Exclusiones estructurales → bucket 99  *(`flg_clean = 99`)*

> Se **saca de la población** (no es "sucio", es *otra* población) a quien cumple alguna de tres
> condiciones en t0.

| Filtro | Qué excluye | n (grano `_cal`, ventana completa, perímetro reenganche) |
|---|---|---|
| `filtro_gtia_hip` | tiene crédito efectivo con **garantía hipotecaria** en t0 | 143 |
| `filtro_colab` | es **colaborador Interbank** en t0−2 | 25 |
| `filtro_mto_pend` | alguna cuenta con **saldo total cero** en la foto de t0 (monto pendiente) | 10 |

`filtro_baja` (cuenta con `cuc` nulo) **no entra**: `n = 0` sobre el universo completo (H86, A40).

Medido sobre el maestro: **178** observaciones en el bucket 99 (`data_quality.json:
master_scope99`), que es exactamente 143 + 25 + 10.

### Paso 3 — Condiciones que sesgan el fit → `dirty`  *(`flg_clean = 0`)*

> Del resto, se marca —pero **no se saca del maestro**— a quien ya estaba **malo en t0**.

| Filtro | Qué marca | n firmado |
|---|---|---|
| `filtro_malo_sf` | mora > 60 en el **sistema financiero** (RCC) en t0 | 61 |
| `filtro_malo_origen` | mora IBK > 60 **o** refinanciado **o** castigado en t0 | 0 |

Medido sobre el maestro: **58** observaciones `dirty` (`data_quality.json: master_dirty`).

> *Reconciliación derivada, no medida directamente:* 61 − 58 = 3. El `CASE` de `70_cal` evalúa el
> bucket 99 **primero**, así que 3 de los 61 `malo_sf` habrían caído antes en una exclusión
> estructural. La aritmética cierra, pero **no hay una medición que descomponga esos 3** — ver §11.

### Paso 4 — Población limpia  *(`flg_clean = 1`)*

> Perímetro reenganche, sin exclusión estructural, sin condición de "malo al origen".

Medido: **119.018** observaciones (`data_quality.json: poblacion_n`), y
178 + 58 + 119.018 = 119.254 = el maestro completo, **sin solape y sin resto**.

### Paso 5 — Población del fit  *(`flg_calib = 1`)*

> De la población limpia, las observaciones que además **se pueden usar para estimar**: tienen PD,
> tienen target maduro a 12 meses, tienen foto de mes y no están duplicadas.

`WHERE` canónico del fit:

```sql
flg_scope_ree = 1 AND flg_clean = 1 AND flg_calib = 1
```

El binding es `falla_cruce_pd = 0`: la fuente de PD arranca en `codmes_mrm = 202312` (H34). El
otro binding es `falla_madurez_12 = 0`: la última cohorte madura es 202506 (H22, A10).

**Resultado — Z1 (ventana de estimación):**

| | |
|---|---|
| Cohortes | **202312 – 202506** (19 meses) |
| Observaciones | **26.348** |
| Defaults / RD12 | **3,3133%** |
| DEP | n = 9.712, RD 2,924% |
| NO DEP | n = 16.636, RD 3,541% |

**Z2 (ventana de aplicación / inmadura):** `codmes` 202507–202604, `pd` no nula, **18.045**
observaciones. **`rd_hist` (serie de LRA):** `codmes` 201901–202506 con `target_12m` no nulo,
**100.973** observaciones. Todo de `outputs_v5/json/data_quality.json`.

### Diagrama del embudo

```
  11.746.259   Paso 0  universo comportamental PP (90 cohortes, 201901-202606)
       │
       │  flg_scope_ree = 1   (marca de reenganche)
       ▼
     119.254   Paso 1  perímetro reenganche (88 cohortes, 201901-202604)
       │
       ├── 178  flg_clean = 99   gtia_hip 143 + colab 25 + mto_pend 10   → OTRA POBLACIÓN
       │
       ├──  58  flg_clean = 0    malo_sf / malo_origen                    → DIRTY (se conserva)
       │
       ▼
     119.018   Paso 4  flg_clean = 1  población limpia
       │
       │  flg_calib = 1  (pd + madurez 12m + foto + sin dup)
       ▼
      26.348   Paso 5  Z1 — ventana de estimación 202312-202506, RD12 = 3,3133%
```

---

## 7. Semántica de los flags

### 7.1 `flg_scope_ree` — **eje de perímetro**

```sql
CAST(CASE WHEN mar.id_value IS NOT NULL THEN 1 ELSE 0 END AS INTEGER)
```

`1` = la observación pertenece al perímetro **reenganche**. `0` = resto del stock PP.

- **No alimenta `flg_clean`** (A36). Son dos preguntas distintas: *¿de qué población es?* y
  *¿está limpia?*. Fundirlas en una columna fue la contradicción P15/H77 de las versiones
  rechazadas del yaml.
- **Riesgo aceptado (A37):** quien omita `flg_scope_ree = 1` en el `WHERE` calibra sobre el stock
  completo, y eso **no falla** — devuelve resultados. Se cubre con un chequeo de **magnitud** en
  `sql_val/v9`: la población del fit debe estar en el orden de 1,3k/mes, no de 1,7M.
- La columna `valida_scope` marca 202605–202606, donde el 0 es falta de fuente y no medición.

### 7.2 `flg_clean` — **eje de limpieza, tres valores**

Sale de **una sola expresión con dos sumas** (forma tomada de la referencia BankBN
`4b_cal.sql#L98-111`):

```sql
CASE
  WHEN filtro_gtia_hip + filtro_colab + filtro_mto_pend > 0 THEN 99
  WHEN filtro_malo_sf  + filtro_malo_origen           = 0 THEN 1
  ELSE 0
END
```

| Valor | Significado | Lectura |
|---|---|---|
| **99** | **Otra población.** Estructuralmente fuera del modelo: garantía hipotecaria, colaborador, o monto pendiente cero en t0. | Se excluye del análisis. No es "sucio", es que la pregunta no aplica. |
| **1** | **Limpio.** Dentro de la población y sin condición que sesgue el fit. | Es la población de calibración. |
| **0** | **Dirty.** Dentro de la población, pero ya malo en t0 (SF o IBK). | Se conserva en el maestro y se exporta aparte, para poder medir el contraste. |

Propiedades:

- **Reconcilia por construcción:** `#99 + #1 + #0 = universo`, sin solape y sin resto. Verificado
  en `sql_val/v8` (`falla_reconciliacion`, `falla_bucket_fuera_dominio`).
- El dominio es **exactamente** {99, 1, 0}. No existe un 98.
- **Ningún filtro se escribe como constante**: los seis salen de `60_filtros`.
- **`falla_foto_t0` NO entra al 99** (A44). El Recibido no excluye a nadie por un mes sin foto: el
  `LEFT JOIN` no matchea, los flags caen a 0 por el `else` de `ENR#L234/#L237/#L238`, y el cliente
  se clasifica por su mora futura. Meterlo en el 99 mandaba la cohorte 202107 entera fuera de la
  población —**1.044 registros del perímetro reenganche, 112.119 del universo** (H102)— y además
  hacía que el 99 significara dos cosas. Vive en `flg_calib`, que es donde están las condiciones
  de **disponibilidad**.
- **`filtro_baja` queda fuera de la suma del 99** (A40, H86).
- `flg_clean` mide limpieza **dentro** del scope que se elija, así que el resto del stock conserva
  su descomposición clean/dirty y el contraste sigue saliendo de esta misma tabla.

### 7.3 `flg_calib` — **eje de calibrabilidad**

```sql
CAST(CASE
  WHEN flg_clean       <> 99
   AND falla_cruce_pd   = 0
   AND falla_pd_rango   = 0
   AND falla_madurez_12 = 0
   AND falla_foto_t0    = 0
   AND falla_dup        = 0 THEN 1
  ELSE 0
END AS INTEGER)
```

`1` = la observación **se puede usar para estimar**. Es un eje de **disponibilidad de dato**, no de
calidad de crédito: por eso `flg_clean = 0` (dirty) sí puede tener `flg_calib = 1`.

Los seis términos:

| Término | Qué exige |
|---|---|
| `flg_clean <> 99` | no ser de otra población |
| `falla_cruce_pd = 0` | tener PD del scorecard (binding: fuente desde `codmes_mrm` 202312) |
| `falla_pd_rango = 0` | PD ∈ (0, 1) estricto |
| `falla_madurez_12 = 0` | `codmes_mrm + 12 ≤ 202606`, i.e. `codmes_mrm ≤ 202506` |
| `falla_foto_t0 = 0` | el mes t0 existe en el cierre mensual (excluye 202107) |
| `falla_dup = 0` | no hay fan-out en el grano |

**Cambio de semántica respecto del artefacto vigente, que hay que declarar en la entrega:** en la
tabla vigente `flg_calib` **era** el flag de scope reenganche
(`Query_PO_calib.sql#L346`: `case when a.flg_reenganche = 1 then 1 else 0 end as flg_calib`, H3).
Aquí `flg_calib` significa "entra al fit" y el scope vive en `flg_scope_ree`. Fase 2 lo verifica
contra el recorte de Z1 en vez de asumirlo (nota en `data_quality.json`).

---

## 8. Exports — los cuatro parquets

Los cuatro son `CREATE TABLE … WITH (format='PARQUET', write_compression='SNAPPY',
external_location='<S3_DATOS>/<sub>/')`. **CTAS exige el `external_location` vacío**: hay que
limpiar antes de re-correr (los `DROP` de `00_reset` no borran S3).

| Script | Tabla | `WHERE` | Grano | n |
|---|---|---|---|---|
| `90_export_master` | `ds_stk_ree_pp_px_master` | `flg_scope_ree = 1` | individual | **119.254** |
| `91_export_clean` | `ds_stk_ree_pp_px_clean` | `flg_scope_ree = 1 AND flg_clean = 1 AND flg_calib = 1` | individual | 26.348 (19 cohortes 202312–202506) |
| `92_export_dirty` | `ds_stk_ree_pp_px_dirty` | `flg_scope_ree = 1 AND flg_clean = 0` | individual | 58 |
| `93_export_macro` | `ds_stk_ree_pp_px_macro` | `flg_scope_ree = 1 AND flg_clean <> 99 AND falla_madurez_12 = 0` | **mensual** (`GROUP BY codmes_mrm`) | 1 fila/cohorte hasta 202506 |

**`90_export_master`** es el que sostiene la entrega: sin él el histórico individual no existe
(clean arranca en 202312 porque `flg_calib` exige PD, y macro ya viene agregado). Renombra
`codmes_mrm → codmes`, `id_value → key_value`, `target_NNm_60 → target_Nm`, `pd_raw → pd`,
`sit_lab_cs_4v → tipo_ingreso_cs`. Los flags viajan **como columnas** y Fase 2 recorta:
`rd_hist` (codmes ≤ 202506 ∧ target_12m no nulo), `fit` (`flg_clean=1 ∧ flg_calib=1`),
`dirty` (`flg_clean=0`).

**`92_export_dirty`** **no es el complemento del clean**: el 99 es otra población y no entra. Lleva
`filtro_malo_sf` y `filtro_malo_origen` para poder analizar por cuál cayó cada fila.

**`93_export_macro`** alimenta la LRA y la selección de variable macro, así que **no exige score**:
el recorte es `flg_clean <> 99` + madurez, no `flg_calib`. Sin `key_value` — es una serie, no un
detalle. Emite `rd12`, `rd09`, `rd06`, `rd12_30`, y los cortes `rd12_clean` / `rd12_dirty` /
`rd12_dep` / `rd12_nodep` para probar sensibilidad sin rehacer el parquet.

> **Advertencia sobre `rd12_ventana_completa` (columna presente, NO usable).** La cabecera original
> del script decía que `miss_12t` contaba el hueco 202107. **Es falso** (H112): cuenta, por
> cliente, en cuántos de los 12 meses futuros no tiene fila en el cierre — o sea **salida de
> cartera**. RD12 por tramo: `miss=0` → 2,85% · 1–2 → 12,94% · 3–5 → 18,29% · 6–8 → 10,49% ·
> 9–11 → 1,30% · 12 → 0,92%. Son **dos poblaciones opuestas**: salida tardía y deteriorada (el que
> cae sale por castigo/refinanciación) y salida temprana y sana (prepago). Restringir a
> `miss_12t = 0` deja una serie de **sobrevivientes** que excluye justo a los que caen: en la
> ventana del fit tira la RD de 3,31% a **1,48%**. **No usar** para elegir la macro ni como
> sensibilidad de RD (A49). Verificado que el pipeline nunca la consumió.

---

## 9. `00_reset` — los 20 `DROP`

Un archivo por tabla, `DROP TABLE IF EXISTS`, en orden `r001`–`r019`. Cubren las 14 de staging,
`60_filtros`, `ds_stk_ree_pp_cal` (`r016`) y los cuatro `px_*` (`r016b`, `r017`–`r019`).

`DROP TABLE` sobre una tabla externa **no borra el S3**. Para re-correr los exports hay que vaciar
`<S3_DATOS>/{master,clean,dirty,macro}/` a mano.

---

## 10. QA — los 11 scripts de `sql_val`

Todos son `SELECT` de diagnóstico. **Convención:** toda columna que empiece con `falla_` debe dar
**0**; las columnas `n_*` se contrastan contra blancos **medidos antes de construir**.

| # | Script | Corre después de | Qué verifica |
|---|---|---|---|
| **v1** | `v1_cobertura_y_grano.sql` | staging | **Cobertura y grano** de 8 tablas (`10_po`, `11_marca`, `20_dm`, `25_sf`, `30_fut_a`, `35_target`, `40_drivers`, `50_pd`): n, meses distintos, min/max, y `n_dup` al grano declarado. Blanco fijo: `10_po` = **90 meses** 201901–202606 (H65). Toda `n_dup` = 0. → H81, H96 |
| **v2** | `v2_reconcilia_vs_medido.sql` | `11_marca` | **Reconciliación contra cifras medidas antes de construir.** Compara el conteo anual de `11_marca` contra los blancos `e1b` hardcodeados (2019 = 13.482 … 2026 = 8.156) y emite el `delta`. Un desvío no es ruido: significa que el build no reproduce la fuente. → H82 (delta 0 en 2019–2024, −1 en 2025 y 2026) |
| **v3** | `v3_target_rangos_y_monotonia.sql` | `35_target` | **Diez controles del target por cohorte:** rango ∈ {0,1}; inmaduro ⇒ `NULL`; maduro ⇒ no-`NULL`; las **cuatro monotonías** (`target_01 ≤ 03 ≤ 06 ≤ 09 ≤ 12`); `target_12m_30 ≥ target_12m_60`; y el cross-check `max_dm_12 > 60 ∧ target_12m_60 = 0` (`falla_mora_no_marcada`), que atrapa un offset o una columna equivocada. → H83: los diez en 0 los 90 meses |
| **v4** | `v4_drivers_y_pd.sql` | `40_drivers`, `50_pd` | **Los defaults silenciosos, hechos visibles por año.** `pct_sin_tipo_ingreso` (debe ser ~100 en 2019–2021 y ~0 desde 2022, U6); `pct_sin_pd` (v4 cubre 202312–202604, H34); reconciliación de `flg_cs_estado`: `n_cs + n_no_cs + n_sin_dato = n`, `n_sin_dato = Σ falla_sin_cta_sueldo`, y `falla_cs_incoherente`. → H87, H88, H97, H98 |
| **v5** | `v5_ancla_pd_invariante.sql` | `50_pd` | **El invariante del ancla de la PD, como columna y no como argumento.** `falla_ancla_scr` = filas donde `codmes_scr ≠ codmes_mrm + 1`. Si alguien vuelve a tocar el ancla, el chequeo se pone rojo solo. Además cruza contra `11_marca`: `falla_marca_sin_v4` debe ser 0 donde hay PD. → H84 (`falla_ancla_scr` = 0 los 8 años; 15.226/15.226, 20.013/20.013, 8.155/8.155) |
| **v6** | `v6_dm_y_sf.sql` | `20_dm`, `25_sf` | **Las dos fuentes que más decidieron el diseño.** `20_dm`: `ctrl_saldo_nulo` (el caso que tapaba el `COALESCE`), `flg_asof_igual_codmes` = 1 en el 100%, `n_cuc_nulo`, y el hueco 202107 como mes **ausente**. `25_sf`: `falla_reestampado` (el `+1` exacto en todas las filas) y `n_centinela` (`cond_max = 9999`). → H85, H86, H89 |
| **v7** | `v7_staging_restante.sql` | staging | **Cierra el hueco de G21:** las 6 tablas de staging que ninguna otra QA toca (`21_gh`, `22_rf`, `23_cst`, `24_colab`, `26_meses`, `30_fut_b`) — cobertura, grano, `n_dup`. Más dos filas sintéticas: `HUECO_202107_en_26_meses` (debe devolver 0 filas) y `PAR_30a_vs_30b` (diferencia de conteos, debe ser 0). |
| **v8** | `v8_gate_reconciliacion.sql` | `70_cal` | **G1 — la reconciliación del gate**, por cohorte. `#99 + #1 + #0 = universo` sin solape ni resto (`falla_reconciliacion`); `falla_bucket_fuera_dominio` (sólo 99/1/0, el 98 no existe); y los cuatro términos del eje de calibrabilidad: `falla_calib_en_99`, `falla_calib_sin_pd`, `falla_calib_sin_madurez`, `falla_calib_con_dup`. Emite `n_ree` y `n_fit`. **Escrita antes de ver un solo número del gate.** |
| **v9** | `v9_gate_funnel_y_magnitud.sql` | `70_cal` | **Funnel marginal de los seis filtros** contra los `n` firmados (`gtia_hip` 130 · `colab` 25 · `malo_sf` 63 · `malo_origen` 0 · `mto_pend` 10 · `baja` 0, sobre el perímetro reenganche y la ventana completa), más `falla_filtro_null`. Y el **chequeo de magnitud de A37**: `n_fit_por_mes` debe estar en el orden de 1,3k, no de 1,7M — es el único control que caza un `WHERE` incompleto, porque omitir `flg_scope_ree = 1` no falla, devuelve resultados. → los deltas 143 vs 130 y 61 vs 63 se explicaron por **grano** (H101, A46) |
| **v10** | `v10_controles_del_cal.sql` | `70_cal` | **Las columnas de control del `_cal` que ninguna otra query mira**, por año: `falla_foto_t0`, `falla_sin_target`, `falla_scope_vs_v4`, `falla_dup`, `n_fuera_valida_colab`, `n_fuera_valida_scope`, `ctrl_asof_igual_codmes`, `max_cuentas_por_cliente`, `n_sin_mes_en_cierre`, las cinco `falla_madurez_*` y su monotonía. *Un control declarado y nunca consultado es peor que no tenerlo: da la sensación de cobertura sin darla.* |
| **v11** | `v11_filtros_grano.sql` | `60_filtros` | **G11 sobre `60_filtros` directamente** — la única tabla del build que ninguna otra QA tocaba: grano (`falla_dup_grano`), **dominio 0/1** de los seis `filtro_*` y de `flg_scope_ree`, `falla_algun_null`, y el `MAX` de cada filtro (un `MAX = 0` delata un filtro que nunca dispara). |

**Cobertura del QA sobre la cadena:** las 16 tablas quedan cubiertas — v1 (8) + v7 (6) + v11
(`60_filtros`) + v8/v9/v10 (`_cal`). Los cuatro `px_*` no tienen QA en Athena; se verifican del
lado de Fase 2 (`data_quality.json` reconcilia `178 + 58 + 119.018 = 119.254`).

---

## 11. Lo que NO tiene sustento en esta cadena

Se listan explícitamente, en vez de racionalizarlos.

1. **`caso_filtros.yaml` está desincronizado en el bloque `gate:`.** El archivo declara
   (L1-5) haber sido *extraído* del SQL, y sus `expr_ref` / `join_pin` efectivamente lo están —
   pero el bloque `gate:` no:
   - `flg_clean_99` dice `"falla_foto_t0 + filtro_colab + filtro_gtia_hip + filtro_mto_pend"`,
     cuando `70_cal.sql` L95 suma **sólo tres** términos (A44 sacó `falla_foto_t0` del 99).
   - `flg_calib` dice cuatro términos; `70_cal.sql` L103-111 tiene **seis** (faltan
     `falla_pd_rango` y `falla_foto_t0`).

   **Manda el SQL.** El yaml debe regenerarse.

2. **`as_of_cierre` fue firmado y no está implementado.** A39 decidió que el `_cal` lleve el mes de
   carga por partición como columna, para que dos corridas separadas en el tiempo sean
   *comparables* en vez de silenciosamente distintas — motivado por H79 (la partición 202602 se
   reescribió completa cuatro meses después). `grep -r as_of_cierre` sobre `sql_prod` devuelve
   **0 hits**. La única columna relacionada, `ctrl_asof_igual_codmes`, mide otra cosa (el
   `as_of_date` de la cuenta, no la fecha de carga de la partición). **El riesgo de
   reproducibilidad de H79/H80 sigue abierto y sin control implementado.**

3. **`119.255` (marca) vs `119.254` (maestro) no está reconciliado al registro.** H82 reconcilia la
   marca contra la medición previa `e1b`; no existe una medición que explique el −1 entre las
   llaves de la marca y las filas del perímetro. Los dos mecanismos posibles se conocen (una llave
   de marca sin fila correspondiente en `10_po` para ese mes resta; un cliente con dos `tip_doc` en
   el mes suma), pero **cuál opera aquí no fue medido**.

4. **La descomposición `61 malo_sf → 58 dirty` es aritmética, no medida.** La diferencia de 3 se
   explica por la precedencia del bucket 99 en el `CASE`, y la suma cierra
   (`178 + 58 + 119.018 = 119.254`), pero no hay una query que cuente el solape
   `filtro_malo_sf = 1 ∧ flg_clean = 99`.

5. **Umbral de default `> 60` días.** Es el criterio del Recibido, heredado sin re-derivación en
   esta cadena. La familia `target_*_30` se emite en paralelo justamente para poder medir la
   sensibilidad, pero **la elección de 60 no se justifica aquí**: es convención de la definición
   regulatoria/interna vigente, no un parámetro derivado en este trabajo.

6. **`filtro_colab` con lag de 2 meses.** El `−2` está tomado del Recibido. La cadena mide su
   *consecuencia* (la ventana válida [201905, 202403], H15/H51) pero **no hay medición que derive
   el 2** frente a un 1 o un 3.

7. **Censura por salida temprana (A50, ABIERTA).** Los registros con `miss_12t ≥ 9` cuentan como
   NO default con ventana de observación casi nula. La censura genuina se acotó en **n = 1.520
   (5,77% de Z1), RD 0,395%**, con impacto contrafactual de **+16,8 bps** sobre el hazard de la
   población (H140). Es propiedad **heredada** de la definición de target del Recibido —idéntica en
   el artefacto vigente (H104: 2 discrepancias en 116.507)— así que no es regresión del rebuild,
   pero **queda sin corregir en la cadena SQL** y entra al MoC.

8. **`23_cst` no filtra producto.** Documentado en §4.6 como lectura del código. No hay medición
   de cuántos castigos entran por productos distintos de PP.

9. **La cobertura de `t_rsk_cta_sueldo` contradice al Recibido y gana la medición.**
   `22_scoring_ree_v3.sql#L14` afirma *"cobertura 100%"*; sobre las dos poblaciones reproducibles
   la cobertura va de **21,4% a 45,4%** (H92, H93, H95). Si la afirmación se midió sobre otra
   población, no dice cuál. Por eso `flg_cs_estado` existe (A42) — pero **cuál de los tres ejes
   consume el modelo no está decidido en el SQL**.

---

## 12. Trazabilidad de la reconstrucción

Cierre de Fase 1 (A43, A47), con la evidencia que lo sostiene:

| Verificación | Resultado | Ref. |
|---|---|---|
| Cero fan-out en toda la cadena | `10_po`, `30_fut_a`, `30_fut_b`, `35_target`, `40_drivers`, `50_pd` = **11.746.259** filas cada una, `n_dup = 0` en las 14 tablas | H81, H96 |
| Reconciliación de la marca | 119.255 llaves, delta 0 contra `e1b` 2019–2024 | H82 |
| Controles del target | los diez en 0 los 90 meses | H83 |
| Invariante del ancla de PD | `falla_ancla_scr = 0` los 8 años | H84 |
| **Equivalencia contra el artefacto vigente, al registro** | **0 filas del viejo sin correspondencia**, 116.507 cruzadas, +2.511 nuevas | H103 |
| Target | `target_1m` **100% idéntico**; `target_12m` con **2 discrepancias sobre 116.507** (0,0017%), ambas en 202007 y 202008 — las dos cohortes cuya ventana de 12m cruza el hueco 202107 | H104 |
| Drivers | `tipo_ingreso_dep` y `tipo_ingreso_cs` **100% idénticos** | H104 |
| PD | **cambió** — `corr(v2,v4) = 0,9096`, `max|dif| = 0,473`. No es desalineación (el ancla está verificada): son **scorecards distintos**, por el cambio de fuente firmado en A9 | H106, A48 |

> Lo que difiere entre el artefacto vigente y esta reconstrucción es **la PD, y sólo la PD**, por
> una decisión firmada. Población, target y drivers reproducen el vigente al registro, con dos
> discrepancias trazadas a una causa conocida y documentada.

---

### Archivos referenciados

- Código: `C:\Users\CARLOS\mcp-runner\proyectos\ppree\sql_prod\` · `…\sql_val\` · `…\explora\`
- Bitácora: `…\Comportamental PP Reenganche\config\ACUERDOS.md`
- Filtros firmados: `…\config\caso_filtros.yaml` (ver §11.1 — bloque `gate:` desincronizado)
- Cifras de población: `…\outputs_v5\json\data_quality.json`
- MoC: `…\config\MoC_REE_2026-07.md`
