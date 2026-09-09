# FEN Overlay — paquete E2E (score directo + calibración PP + universo 14M + artifact)

Paquete **autocontenido** del overlay de estrés FEN (El Niño costero) sobre la PD del PP de Interbank.
Objetivo: que la máquina que **recibe** este git (con acceso AWS) corra las queries, baje los insumos, y
**engrane** los datos al artifact simulador. Uso declarado: **originación / pricing**, NO ECL/provisiones/capital.

> **Estado (2026-09-08):** Validador MRM = **APTO CON CONDICIONES**. Auditoría = **NO DESPLEGAR** hasta cerrar A1–A7
> (gobierno). La **metodología va bien encaminada**; faltan 1 decisión de diseño + 3 fixes + 2 mediciones + expediente.
> Ver [ENGRANAJE](#2-el-engranaje-e2e-corregido) y [Condiciones](#5-condiciones-bloqueantes-pendientes). **Handoff paso a paso: [HANDOFF_IA.md](HANDOFF_IA.md).**

---

## 1. Qué trae cada pieza (datos / queries / de dónde)

| # | Insumo | Query / fuente | Grano | Cómo vuelve |
|---|---|---|---|---|
| A | **Score directo + reestructurado + geo** por persona | tabla `disc_model_owner.mca_bd_reniec_xy_r_reest` (19,6M RENIEC). Diccionario: `Downloads/diccionario_variables_R_reestructurado.xlsx` | cliente | join por `key_value` |
| B | **Calibración PP VC** (PD calibrada + score) | proyecto **`proyectos/ppvc`** — motor en `sql_score/30_scr_cal.sql` (`scr_ppvc_cal`), insumo `ds_adm_pp_cdpp_cal`; a01 = altas | celda/cliente | ya desplegada |
| C | **Altas PP — 3 meses (libro vigente)** 202605–202607 | **`proyectos/fen_valida_rd/sql_val/j03_altas_recientes.sql`** | cliente (~pocos k/mes) | CSV (output) |
| C2 | **Altas PP — validación** 202301–202507 (RD madura) | **`proyectos/fen_valida_rd/sql_val/j01_altas_1a1.sql`** | cliente (81 728) | CSV (output) |
| D | **Universo 14M scoreado 202608** ⨝ score directo FEN | **`sql_prod/k01_universo_fen_202608.sql`** (CTAS→parquet) sobre `scr_vcadmbnk_final_hist_rsk_cal_2606_2608` (proyecto `score_2606`) | cliente (~14M) | **`-Bajar`** (parquet) |
| D2 | **Universo — agregado para el artifact** | **`sql_val/k02_universo_fen_agg.sql`** (celdas grado×R×tipo×pac) | celda (~150) | CSV pegable |
| 0 | **Chequeo de esquema** (antes del CTAS 14M) | **`sql_val/k00_esquema.sql`** | — | CSV |
| E | **Score indirecto `s`** (dependencia agua, distrital) | LOCAL: `elnino_ibk/02_pipeline/out/sectores_agua_distrito.csv` (ubigeo INEI → `s_total`, 1891 distritos). Censo 2017. NO viene del banco | distrito | join local por `ubigeo_dom` |
| F | **IBK+ (recuperación regional)** | LOCAL: `elnino_ibk/02_pipeline/ibk_panel.json` (consumo IBK+ var% real interanual, nac + 12 deptos, 202201–202606) | depto×mes | join local por `depto` (2 díg. INEI) |
| G | **γ / ICEN** (intensidad lluvia) | `met.igp.gob.pe/datos/ICEN.txt` (público). Selector externo Apoyo (base/pesimista) | escenario | — |
| H | **Artifact simulador** | `elnino_ibk/03_deck/estres_fen_pp_cdpp.html` (URL `claude.ai/code/artifact/d1098522-...`) | — | se re-embebe y republica |

**Orden de ejecución en el banco:** `k00` (esquema) → `k01` (CTAS 14M, con `-Bajar`) → `k02` (agregado) · en paralelo `j01`/`j03` (altas).

---

## 2. El engranaje E2E (corregido)

**Cadena:** `score directo REEST (R_reest) + score indirecto s (por ubigeo domicilio) → e = wF·(R_reest/5) + wA·s + κ·d·s`
`→ PD base PP (pcal × ft(IPC, proyección 1 mes)) → overlay λ·γ·costa·e′ (con recuperación IBK+) → PD estresada → re-grada Gs.`

**Las dos palancas (decopladas):**
- **Base = nivel NACIONAL** (`ft` escalar vía IPC). Selector de intensidad = **escenario Apoyo** (base/pesimista; diff IPC ~+0,3–0,4pp).
- **Overlay = DIFERENCIAL geográfico** (costa − promedio nacional), anclado al **β empírico (~0,8–1,8 pp/año)**. Ortogonal al `ft` porque un escalar nacional no lleva geografía.

**No-doble-conteo = separación por CANAL** (no la "ortogonalidad-por-diferencia" abstracta, que es tautológica):
- Base ⟶ canal **precio/inflación nacional** del FEN.
- Overlay ⟶ canal **físico/local costeño** (inundación → ingreso/colateral), incremental y **neteando** la porción de inflación‑alimentos doméstica ya embebida en el IPC (el solape es REAL — BIS WP1276/Perú).

**Regla que preserva el nivel (Feynman):** re-anclar a la LRA post-overlay (media preservada) es lo que blinda el nivel — pero **choca con la monotonía estricta PD*≥PD₀** ⇒ **elegir carril: REDISTRIBUTIVO** (costa sube, interior baja marginal; recomendado pricing) vs ADITIVO (sube nivel = apetito declarado).

**Constantes del motor:** `λ=√(ρ/(1−ρ))`, `κ=0,25`. **⚠ ρ:** el artifact usa 0,15 (HIPOTECARIA, mal aplicada a consumo) → **reconciliar a 0,0332** (other retail). Ver Condiciones.

---

## 3. Tabla componente → fuente verificada → veredicto

*(Revisión bibliográfica, citas verificadas en fuente primaria; detalle en [FUENTES.md](FUENTES.md).)*

| Componente | Fuente | Veredicto |
|---|---|---|
| Umbral Vasicek/Merton + ASRF, estrés = shift del factor | Merton 1974 · Vasicek 2002 · Gordy 2003 · BCBS 2005 | **ESTÁNDAR** |
| `λ=√(ρ/(1−ρ))` · ρ base 0,0332 (other retail) | Basel CRE31.16 | **ESTÁNDAR / ADECUADO** |
| **ρ=0,15 en el overlay** | Basel CRE31.14 = correlación HIPOTECARIA | **🔴 NO-SOPORTADO** (fix → 0,0332) |
| PIT/TTC + factor macro `ft` | Carlehed-Petrov 2012 | **ESTÁNDAR** |
| Monotonía / PD*≥PD₀ / FOSD | Hadar-Russell 1969 | **ESTÁNDAR** (propiedad, no mandato) |
| DiD / diferencial costa−no costa | Card-Krueger 1994 · Bertrand-Duflo-Mullainathan 2004 | **ESTÁNDAR/DEFENDIBLE** (parallel trends) |
| Overlay / Post-Model Adjustment gobernado | ECB 2024 (IFRS9 overlays) · EBA | **DEFENDIBLE** (declarar transfer ECL→pricing) |
| Juicio experto gobernado | Fed/OCC **SR 11-7** (2011) | **ESTÁNDAR** (permite ajustes conservadores) |
| Falacia ecológica (score distrital→individuo) | Robinson 1950 | **ESTÁNDAR** (usar como límite declarado) |
| Selección adversa ("conservador ≠ seguro") | Stiglitz-Weiss 1981 | **DEFENDIBLE** |
| FEN → inflación/PBI | Cashin-Mohaddes-Raissi 2017 · Brunner 2002 · BIS WP1276/2025 Perú | **ESTÁNDAR** |
| Físico (inundación) → default | ECB WP3224/2025 (+0,7pp/trim firma inundada) | **ESTÁNDAR** UE/EE.UU. |
| **ENSO → crédito (incl. Perú)** | **Collier-Katchova-Skees 2011** (Piura MFI: +3,6% portafolio reestructurado) · De Marco-Limodio (JFE, El Niño & US banks) · Ecological Economics 2025 (51 países, NPL) | **DEFENDIBLE con evidencia directa** |
| Magnitud ~0,8–2,6 pp/año costa | vs. elasticidad ECB WP3224 | **DEFENDIBLE** (+5–17pp = STRETCH) |
| Solape físico↔precio (doble conteo) | BCBS 2021 · BIS WP1276 Perú | **REAL** → netear |

**A declarar (no huecos):** SR 11-7 es de la Fed (ubicar la norma **SBS** aparte, no inventarla); overlay ECL→pricing y S-W→pricing geográfico son extensiones; FOSD es propiedad; Perú no está en el GVAR de Cashin (usar Chile + BIS Perú); no existe "FEN→PD bancaria Perú" puntual (Collier et al. es lo más cerca).

---

## 4. Cómo se engrana — DOS artifacts separados

| Artifact | HTML | Datos | URL |
|---|---|---|---|
| **1 · Altas** (libro vigente que "se mueve") | `elnino_ibk/03_deck/estres_fen_pp_cdpp.html` | `j03` (3 meses 202605‑07) · valida con `j01` | `claude.ai/code/artifact/d1098522-...` (ya publicado) |
| **2 · PEA / Universo** (los 14M scoreados) | `elnino_ibk/03_deck/estres_fen_pp_universo.html` | `k02` (agregado del universo 202608) | **por publicar** tras inyectar `k02` |

Para cada uno: **(a)** parsear el CSV/parquet; **(b)** construir las celdas `{g,r,tipo,pac,n,pd(,rd)}` (el Universo NO trae `rd`); **(c)** pegar `s` real por `ubigeo_dom` (E) e IBK+ por `depto` (F); **(d)** reemplazar `var DATA=` (regex `/var DATA=\{[\s\S]*?\]\};/`, NO toca `MAPDATA`); **(e)** aplicar los fixes del motor (§5); **(f)** verificar headless; **(g)** publicar (Altas → misma URL d1098522; Universo → nueva URL). Detalle en **[HANDOFF_IA.md](HANDOFF_IA.md)**.

> **Todo el score sale de `mca_bd_reniec_xy_r_reest`** (directo `r_label/r_nivel` + geo `r_label_geo` + **REESTRUCTURADO** `r_label_reest` + físico `dist_ma_m/exp25/exp50/flg_ma_*` + ubigeos `ubigeo_inei_nodo/formato_inei/reniec` + cascada `flg_nodo/concordancia`). `j01`/`j03`/`k01` ya traen el set **completo** — si se necesita otro campo de esa tabla, se agrega ahí (es la única fuente del score).

---

## 5. Condiciones bloqueantes pendientes

**Modelo (validador):** 1) elegir carril **redistributivo** vs aditivo; 2) **ρ → 0,0332** (una sola parametrización); 3) anclar γ al empírico y **topear al IC** (+7pp solo display, amurallado del pricing); 4) cambiar el corte **R4/R5** por gate Pacífico+s (la RD lo contradice: R45≈R123) o justificarlo; 5) correr **Test A** (PD base IPC con-FEN vs sin-FEN) + **Test B** (mean(PD*)=LRA) + ortogonalidad.
**Gobierno (auditoría A1–A7):** repo gobernado (config, no HTML) · segregación + validación independiente · acta de Comité · base PP firmada · reclasificar "7,31≈7,24" a QA (no "validado") · frontera dura efectiva (no ECL) · fair-lending · sunset con gatillo ICEN · pre-registrar cohorte 2026 · score vintage. → los **15 papeles** del expediente.

**Riesgo residual (aun cerrando todo):** medio-alto — ancla de un solo evento (Yaku), cero OOS al desplegar, insumo R con sesgo de reporte. Tolerable para originación/pricing bajo gobierno; **intolerable para ECL/capital**.
