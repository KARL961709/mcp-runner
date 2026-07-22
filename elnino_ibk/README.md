# Proyecto FEN-IBK — Exposición a El Niño costero por distrito (R0-R5)

Análisis de riesgo crediticio del Fenómeno El Niño costero para Interbank.
Clasificación distrital ordinal **R0-R5** y su cruce con la mora (RD) de la cartera.

## Estructura
```
01_inputs/      Bases de información (archivos locales + manifiesto de tablas Athena). Ver INPUTS.md
02_pipeline/    Genera los grupos R0-R5 desde los inputs (classifier→recover→gen_grado_v3→gen_v3_sql→CTAS). Ver README.md
03_queries/     Consultas Athena: bases ENR_*, RD por grupo×codmes (cohorte cerrado), n%/composición. Ver README.md
03_deck/        Deck + mapa coroplético R0-R5 (mapa_fen_v3.html).
05_entregables/ Metodología, auditoría de fuentes, definición del problema.
_legacy/        Versiones previas (grado v1/v2, scratch, mapas/deck v1, sinpad_pdf). No usar.
```

## Idea central
El nivel FEN **no** predice mora basal (es plano fuera de evento); es un **overlay de estrés**:
en la ventana El Niño 2023 los distritos más expuestos (R4+R5) muestran +RD, sobre todo en **TC**
(~5pp de spread) y de forma menor en PP. El grado se construye solo con peligro lluvia/inundación/huaico
de la vertiente del Pacífico (gate validado: ~90-98% del daño FEN histórico es Pacífico).

## Reproducir de cero
1. `cd 02_pipeline && node gen_grado_v3.js && node gen_v3_sql.js`
2. CTAS `disc_model_owner.grado_elnino_ubigeo_v3` desde `02_pipeline/out/_v3_create.sql` (AWS CLI, workgroup `ibk-discovery-riesgos-work-group`).
3. `03_queries/00_bases/01_grado_elnino_lookup_v3.sql` (lookup armonizada).
4. `03_queries/00_bases/02..05_*.sql` (bases ENR_* stock TC/PP/VC + altas).
5. RD y composición: `03_queries/10_rd_codmes/*` y `03_queries/20_composicion/*`.
