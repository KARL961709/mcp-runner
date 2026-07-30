-- ============================================================================
-- V2. Reconciliacion contra cifras MEDIDAS antes de construir (blanco fijo).
--     H17  marca = 119,255 llaves (key_value, codmes_desembolso)
--     e1b  por anio: 2019=13482 2020=5019 2021=14157 2022=24252 2023=18951
--                    2024=15226 2025=20014 2026=8156
--     Un desvio aca no es ruido: el build no reproduce la fuente.
-- ============================================================================
SELECT
  SUBSTR(codmes_mrm, 1, 4)                          AS anio,
  COUNT(*)                                          AS n_construido,
  CASE SUBSTR(codmes_mrm, 1, 4)
    WHEN '2019' THEN 13482 WHEN '2020' THEN 5019  WHEN '2021' THEN 14157
    WHEN '2022' THEN 24252 WHEN '2023' THEN 18951 WHEN '2024' THEN 15226
    WHEN '2025' THEN 20014 WHEN '2026' THEN 8156 END AS n_medido_e1b,
  COUNT(*) - CASE SUBSTR(codmes_mrm, 1, 4)
    WHEN '2019' THEN 13482 WHEN '2020' THEN 5019  WHEN '2021' THEN 14157
    WHEN '2022' THEN 24252 WHEN '2023' THEN 18951 WHEN '2024' THEN 15226
    WHEN '2025' THEN 20014 WHEN '2026' THEN 8156 END AS delta
FROM disc_model_owner.ds_stk_ree_pp_11_marca
GROUP BY 1
ORDER BY 1
