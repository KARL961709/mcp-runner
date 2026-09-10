# BUILD_ARTIFACTS — para la IA Claude en la PC del banco

**Objetivo:** dejar LISTOS los 2 artifacts con dato REAL de banco, **engranando** los CSV agregados a los templates existentes (que ya traen el motor y la capa IBK+ v3). **No re‑escribas el motor ni el diseño** — solo reemplazas el bloque de datos `var DATA={...}` y activas el toggle. Salida: los 2 HTML verificados y publicados (o guardados para Carlos).

> **Frontera / MRM (respétala):** uso originación/pricing, NO ECL/capital. Metodología **APTA CON CONDICIONES** — **no** etiquetes "validado". Los escenarios son **gobierno, no pronóstico**.

---

## 0) Insumos

**Templates** (en `elnino_ibk/03_deck/`, ya con motor + IBK+ v3, celdas hoy proxy):
- `estres_fen_pp_cdpp.html` → **Altas** (URL `d1098522-...`)
- `estres_fen_pp_universo.html` → **PEA** (URL `c73696cc-...`)

**CSV** (en `output\` tras correr el `./Go` de abajo — son FULL, no truncados a 100):
| CSV | Para | Columnas |
|---|---|---|
| `s04a_altas_reest` / `s04a_altas_dir` | celdas **Altas** (`cells` / `cellsDir`) | grado,tipo,r,n,pd,rd,s,ibk_c |
| `s04b_pea_reest` / `s04b_pea_dir` | celdas **PEA** | grado,tipo,r,n,pd_facil,pd_cd,s,ibk_c |
| `s04c_agg_mapa_distrito` | mapa por distrito (860) | ubigeo_dom,depto,n,s,share_r45_dir,share_r45_reest,avg_r_dir,avg_r_reest |
| `s05_dist_reest` / `s05_dist_dir` | **migración uno‑a‑uno EXACTA** por escenario (PEA) | escenario,g0,g1,n,pd0,pd1 |

---

## 1) CORE — re‑embeber celdas reales (los 2 artifacts)

Construye desde los CSV y **reemplaza el bloque `var DATA={...};`** (regex `var DATA=\{[\s\S]*?\]\};`). **No toques nada más** (motor, `MAPDATA`, `IBKC`/`IBKNORM`/`IBKYAKU`/`WORSTREF`, CSS).

**Formato de celda** (idéntico al actual + `s` e `ibk_c` reales):
```
{"g":"G3","r":"R2","tipo":"NO_DEP","pac":1,"n":337,"pd":0.03494,"rd":0.0,"s":0.031,"ibk_c":0.351}
```
- `r` = `"R"+r` (el entero del CSV). `pac` = `(r>=1)?1:0`.
- **Altas:** `pd` = columna `pd`. `rd` = columna `rd` — **viene vacía** (libro 202605‑207 inmaduro): pon `rd:null` y **no** calcules RD por celda (ver §4).
- **PEA:** `pd` = `pd_facil` (define el grado). `rd` **no aplica** (omite el campo).

**`DATA.cells`** = filas del CSV `_reest`. **`DATA.cellsDir`** = filas del CSV `_dir`. *(Al existir `DATA.cellsDir`, el botón "Directo" se activa solo — `renderRtog` lo detecta con `!!DATA.cellsDir`.)*

**Recalcula** (ponderado por `n`, desde `cells`):
- `DATA.total` = `{n: Σn, pd: Σ(n·pd)/Σn, rd: <ver §4>}`
- `DATA.byGrado` = por grado `[{g, n: Σn, pd: Σ(n·pd)/Σn}]`

**Preserva sin cambios:** `DATA.grados` = `["G1".."GR"]`, `DATA.cutoffs` = `[0.00871,0.02581,0.04542,0.07551,0.11283,0.15813]`.

---

## 2) EXACTO uno‑a‑uno (solo PEA) — la capa que refleja el "verdadero cambio"

El motor estresa el **promedio** de cada celda (aproximación por Jensen). El **exacto** es por cliente y ya está en `s05_dist`. Embébelo y haz que los **6 escenarios de gobierno** usen el exacto (el motor queda solo para sliders custom).

Construye `var EXACT = {reest:{...}, dir:{...}}` desde `s05_dist_reest/dir`, indexado por escenario, con **índices de grado 0..6** (G1=0…GR=6) para compactar:
```
EXACT.reest["ESC1"] = { flows:[[g0,g1,n],...], pd0:<Σn·pd0/Σn>, pd1:<Σn·pd1/Σn> }
```
- `flows` = filas `[índice(g0), índice(g1), n]` → alimenta la migración exacta (HOY→CON FEN).
- La distribución CON‑FEN por grado = marginal de `g1`; la HOY = marginal de `g0`.

**Cableado** (mínimo, en `compute()`): si `activeScen` es uno de los 6 y hay `EXACT[vista][activeScen]`, devuelve **sus** `flows`, `aPds=pd1`, `aPd0=pd0` en vez de los del motor. La vista = `useReest?'reest':'dir'`. Si es escenario custom (sliders) o Altas → usa el motor como hoy.

*(Altas: no hay `s05` de altas → usa el motor sobre las celdas reales, que es la aproximación validada. No inventes datos.)*

---

## 3) Mapa (opcional, mejora) — refrescar con R real por distrito

`MAPDATA.feats` ya trae geometría + `r`/`s` del clasificador. Puedes refrescar por `ubigeo_dom` con `s04c`: `avg_r_dir`/`avg_r_reest` (R real por cliente, cambia con el toggle) y `share_r45_*` (recorte). Si no lo haces, el mapa sigue con el R embebido (válido). **No** borres la geometría.

---

## 4) RD del artifact de Altas (inmaduro)

El libro 202605‑207 no tiene RD (aún no cumple 12m). **No** muestres "RD real ✓" por celda. Opciones (elige la más limpia): deja `DATA.total.rd = 0.07239` como **ancla de validación** rotulada *"RD 12m validada en libro maduro (81 728, 202607) — el libro reciente es inmaduro"*, o quita el sub‑KPI de RD. La calibración se validó sobre el libro maduro y se aplica igual al reciente.

---

## 5) Compacidad ("vectorizado")

El dato es agregado (celdas ~84, mapa ~860, exacto ~150 filas) → JSON directo pesa poco (~+100KB sobre 418KB). No hace falta comprimir agresivo. Sí: usa **índices de grado 0..6** en `EXACT.flows` y números redondeados (5 dec pd, 4 dec s/ibk_c). Mantén `cells`/`cellsDir` como array de objetos (el motor lee `c.g`,`c.r`,…).

---

## 6) Verificación (obligatoria, antes de publicar)

Render headless (Chrome `--headless=new --screenshot`, `--user-data-dir` propio, `--virtual-time-budget=9000`) y confirma:
1. **Sin errores** en consola.
2. **PEA:** `aPd0 ≈ 0,18229` (= `pd_base` de `qa02`) y, en ESC1, `aPds ≈ 0,23248` (= `pd_estres` uno‑a‑uno de `qa02`, vista reest). Si cableaste §2, debe dar **exacto**; si solo motor, la brecha debe ser chica (repórtala).
3. **Toggle Directo** activo (ya no dice "pendiente") y cambia las celdas.
4. **IBK+**: el mapa de resiliencia y el spark siguen igual (no los tocaste).
5. **Migración** y densidad se mueven con los escenarios.

---

## 7) Salida
Los 2 HTML listos. Publícalos (Artifact) y entrega a Carlos las URLs, o guarda los HTML si no tienes la herramienta de publicar. Reporta: qué embebiste, el check del §6 (números), y cualquier brecha motor‑vs‑exacto.

> Contexto extra si lo necesitas: `HANDOFF_IA.md` (mapa del pipeline), `RUNBOOK_GO.md` (secuencia), `README.md` (§5 condiciones MRM).
