# 03_queries — Consultas Athena (RD por grupo y composición)

JOIN oficial: **por NOMBRE** (dep+prov+dist normalizado) contra `grado_elnino_lookup_v3`
(el cod_ubi_domicilio de RENIEC NO está homologado con INEI).

## Orden de ejecución
1. **00_bases/** — crear tablas (una vez, o cuando cambie la data):
   - `01_grado_elnino_lookup_v3.sql` (requiere `grado_elnino_ubigeo_v3` del pipeline)
   - `02_enr_stock_tc.sql`, `03_enr_stock_pp.sql`, `04_enr_stock_vc.sql` (stocks)
   - `05_enr_altas_vc.sql` (altas / originaciones, 3 targets)
2. **10_rd_codmes/** — RD por grupo R0-R5 × codmes, **cohorte cerrado** (def maduro, MALO=1 sobre BUENO/MALO):
   - `rd_stock_tc.sql`, `rd_stock_pp.sql`, `rd_stock_vc.sql`
   - `rd_altas_tc.sql`, `rd_altas_pp.sql`, `rd_altas_vc.sql` (VC = combinado PP+TC)
3. **20_composicion/** — n y %n por grupo × codmes, **sin cohorte cerrado** (todas las filas, incluye período más reciente):
   - `npct_stock_tc.sql`, `npct_stock_pp.sql`, `npct_stock_vc.sql`, `npct_altas_tc_pp.sql`

## Exportar a Excel
`node run_sql_to_excel.js` ejecuta TODOS los .sql de `10_rd_codmes/` y `20_composicion/`
en Athena (AWS CLI, profile `ibk`, workgroup `ibk-discovery-riesgos-work-group`) y escribe
`resultados/RD_grupos_FEN.xlsx` (una hoja por consulta). Requiere `aws sso login --profile ibk` vigente.

## Madurez (cohorte cerrado)
- Stock: `def12` válido hasta `codmes_mrm <= '202504'`.
- Altas: `DEF12_*` válido hasta `codmes <= 202503`.
- Composición (%n): NO requiere madurez → usa todos los codmes.

## Hallazgo resumido
- **TC**: señal FEN fuerte — spread R4+R5−R1 ~5pp en la ventana El Niño 2023 → ~1.4pp benigno.
- **PP**: señal moderada (~2pp en ventanas que solapan el evento, →~0.2pp), concentrada en R5; altas PP ≈ 0.
- **VC** (cliente, worst-of): historia más larga (202201+), pico ~5.2pp en 202306.
- El nivel FEN **no** ordena riesgo basal; es un **overlay de estrés** que se enciende con el evento, sobre todo en TC y en R4+R5.
