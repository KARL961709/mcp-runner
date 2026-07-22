# 02_pipeline — Generación de los grupos R0-R5 desde los inputs

Convierte los insumos (`01_inputs`) en la clasificación distrital **R0-R5** y la materializa en Athena.

## Flujo
```
01_inputs/*  ──▶ recover_missing.js ──▶ intermedios/_recuperados.json
                    (distritos faltantes por centroide→cuenca)
01_inputs/*  +  intermedios/* ──▶ gen_grado_v3.js ──▶ out/grado_fen_v3.csv
                    (score = severidad+recurrencia+fragilidad+exposición;
                     gate Pacífico → R0; R1-R5 = Fisher-Jenks k=5 sobre score Pacífico)
out/grado_fen_v3.csv ──▶ gen_v3_sql.js ──▶ out/_v3_create.sql
                    (CTAS de disc_model_owner.grado_elnino_ubigeo_v3, ~167KB)
out/_v3_create.sql ──▶ [AWS CLI] ──▶ Athena: grado_elnino_ubigeo_v3
                    ──▶ 03_queries/00_bases/01_grado_elnino_lookup_v3.sql ──▶ grado_elnino_lookup_v3
```

## Archivos
- `fen_classifier.js` — clasificador único de peligro FEN (lluvia/inundación/huaico).
- `recover_missing.js` — recupera ~25 distritos faltantes (centroide→cuenca); Chosica→Cuenca Rímac.
- `gen_grado_v3.js` — **generador principal** del score y los niveles R0-R5.
- `gen_v3_sql.js` — arma el CTAS de la tabla Athena desde el CSV.
- `intermedios/` — insumos intermedios (`_recuperados.json`, `escenario_severo_cuenca.csv`, `grado_integrado_v2.csv`).
- `out/` — salidas: `grado_fen_v3.csv` (1890 distritos), `_v3_create.sql`.
- `tests/` — `test_costa_vs_interior.js` (valida gate Pacífico), `test_tail_interior.js` (tail no-Pacífico).
- `node_modules/` — dependencia `xlsx` (lectura de los .xlsx de inputs).

## Correr
```
cd 02_pipeline
node gen_grado_v3.js   # -> out/grado_fen_v3.csv  (distribución R0 1117/R1 66/R2 199/R3 298/R4 139/R5 71)
node gen_v3_sql.js     # -> out/_v3_create.sql
# luego: aws athena ... (CTAS grado_elnino_ubigeo_v3) y correr 03_queries/00_bases/01_*.sql
```

## Definición del score (gen_grado_v3.js)
- **sev** = max(min(dmg_cuenca/capCuenca,1), min(dmg17_propio/capD17,1)), con **topes = p95 data-driven** de cada distribución (Pacífico, daño>0): capCuenca≈121,041 · capD17≈3,052. Se calculan dinámicamente en cada corrida (sin números mágicos).
- **rec** = n_eventos/4  (eventos: 1983, 1998, 2017, 2023-24)
- **fra** = (a2017 + a2324)/2
- **exp** = pct_expuesto/100
- **score** = sev+rec+fra+exp  (0 si no-Pacífico → R0)
- Niveles R1-R5: cortes Fisher-Jenks sobre el score de los distritos Pacífico (≈ 0.66 / 1.40 / 2.20 / 3.05).
