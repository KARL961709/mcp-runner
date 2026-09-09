# HANDOFF — estado actual del overlay FEN y cómo engrana al artifact

Todo lo necesario está en el git. Uso: **originación/pricing**, NO ECL/capital.
La **secuencia autoritativa y actual está en [RUNBOOK_GO.md](RUNBOOK_GO.md)** — este doc es el mapa/estado.

> **LÍMITE MRM (léelo primero):** metodología **APTA CON CONDICIONES**, **NO DESPLEGABLE** hasta cerrar gobierno.
> NO etiquetes el resultado como "validado". El `7,31≈7,24` es un **gate de anclaje**, no validación. Ver [README §5](README.md).

## Pipeline vigente (orden en RUNBOOK_GO.md)

| Paso | Query (`-Only`) | Crea | Para qué |
|---|---|---|---|
| 0 | `k00_esquema`, `k00b_llaves` | (checks) | valida columnas de universo/reniec/altas + match de llave (64=64, ~70% = cobertura geo real) |
| 1 | `s01_seed_s_indirecto` | `fen_s_indirecto` | `s` por distrito (Censo, cortes fijos 0,20 S0–S4) |
| 1 | `s02_seed_ibk_plus` | `fen_ibk_plus` | resiliencia IBK+ por depto (metodología abajo) |
| 2 | `s03b_overlay_altas_202605_202607` | `fen_overlay_altas_202605_202607` | "mca con todo" ALTAS (trae rd12 inmaduro) |
| 2 | `s03_fen_overlay_input_202608` | `fen_overlay_input_202608` | "mca con todo" PEA (~9,1M) |
| 3 | `s04a` / `s04b` / `s04c` | (agregados chicos) | celdas grado×R×tipo + mapa distrito → **re-embeber el artifact** |
| 4 | `s05_escenarios_202608_dir` / `_reest` | `fen_overlay_escenarios_202608_dir/reest` | PD estresada + grado por los **6 escenarios**, una tabla por vista R |
| QA | `qa01_salud_input`, `qa02_escenarios` | (checks) | sanidad del insumo + control del motor (`viola_*` deben ser 0) |

**Superseded — NO correr:** `k01_universo_fen_202608`, `k02_universo_fen_agg`, `s04_fen_overlay_agg`. El "pegar `s`/IBK+ a mano" viejo ya no aplica: todo se consolida en el banco (s01/s02/s03).

## IBK+ — metodología v3 (la vigente)
- Magnitud = **desviación de su PROPIA normal pre-FEN** (mediana 202503–202602), **NO vs el promedio nacional**.
- Gate de recuperación anclado a **Yaku-2023** (FEN costero previo). Atenúa **SOLO si RESILIENTE** = hoy ≥ su normal **Y** recuperó en Yaku. Regímenes R (atenúa) / V (vigilar) / F (frágil).
- **Depto sin serie propia → tratado como el PEOR observado (Junín, recuperación más lenta) → sin alivio.** Nunca el nacional, nunca "resiliente sin dato".
- Solo **12 deptos + nacional** tienen serie (13 sin, incl. costeros **Tumbes/Callao/Tacna/Moquegua**).
- **SOLO atenúa** — entra como `max(ibk_c,0)`, nunca sube el estrés.

## Motor (idéntico en el artifact y en `s05`)
`PDx = Φ( Φ⁻¹(pd0) + λ·γ·pac·e·(1−rec) )`, con `λ=√(ρ/(1−ρ))` `ρ=0,0332`, `e=wF·d+wA·s+κ·d·s` (`κ=0,25`), `d=R/5`, `rec=clamp(recup+0,02·max(ibk_c,0),0,1)`, `s`=s_total real o proxy (NO_DEP 0,65 / DEP 0,25), `pac`=gate Pacífico (R≥1 → si 0, PDx=pd0). Grado por cortes PD del libro. **Validado 1‑a‑1 con `k05` (36/36 = simulador).** Escenarios (γ,wF,wA,recup): ESC1 4,2/.5/.5/0 · ESC2 3/.5/.5/.3 · ESC21 3/.6/.4/.3 · ESC22 3/.5/.5/.5 · ESC31 2/.6/.4/.3 · ESC32 2/.5/.5/.5.

## Toggle R (Directo vs Ajuste Geo)
- **Directo** = `r_dir` (nativo, ubigeo declarado). **Ajuste Geo** = `r_reest` (geo, point-in-polygon). Cada vista: `d=R/5`, `pac=R≥1`, recorte `R≥4`.
- El artifact alterna las dos; `s05` las materializa en 2 tablas hermanas (`_dir`, `_reest`).

## Los DOS artifacts (`elnino_ibk/03_deck/`)
- **`estres_fen_pp_cdpp.html`** (Altas, URL `d1098522-...`) — trae `rd`.
- **`estres_fen_pp_universo.html`** (PEA, URL `c73696cc-...`) — sin `rd`.
- Ambos **ya tienen la capa IBK+ v3** (inyectada) y el toggle Directo/Ajuste Geo. Las **celdas grado×R aún son proxy** hasta re-embeber los CSV de `s04a/b/c`.
- Para pasar a datos REALES: correr `s04a/b/c` → pegar los CSV al origen → reconstruir `var DATA={...}` (regex `/var DATA=\{[\s\S]*?\]\};/`, **no tocar `MAPDATA`**) → republicar a la **MISMA URL** (Artifact publish con `url=`).

## Mapa de archivos
```
proyectos/fen_overlay/
  RUNBOOK_GO.md      <- SECUENCIA AUTORITATIVA (leer primero)
  HANDOFF_IA.md      <- este archivo (estado/mapa)
  README.md          <- engranaje + condiciones MRM (§5)
  FUENTES.md         <- bibliografía verificada
  sql_val/  k00_esquema, k00b_llaves, s04a/b/c, k05_check_escenarios, qa01, qa02
  sql_prod/ s01, s02, s03, s03b, s05_escenarios_202608_dir, s05_escenarios_202608_reest
elnino_ibk/03_deck/  estres_fen_pp_cdpp.html, estres_fen_pp_universo.html  (los 2 artifacts)
```
