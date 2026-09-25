-- e23_qa1_agregados.sql | QA integridad + PD promedio por escenario (esperado: esc1~7.6, esc2~esc3~8.4, esc4~9.7; nulls 0)
SELECT COUNT(*) AS n,
  SUM(CASE WHEN pit IS NULL THEN 1 ELSE 0 END) AS null_pit,
  SUM(CASE WHEN pd_esc4_macropes_fen50 IS NULL THEN 1 ELSE 0 END) AS null_esc4,
  SUM(CASE WHEN pd_esc2_fen70 NOT BETWEEN 0 AND 1 THEN 1 ELSE 0 END) AS pd_fuera_01,
  ROUND(100*AVG(pd_raw),3)                 AS pd_raw,
  ROUND(100*AVG(pd_ttc),3)                 AS pd_ttc,
  ROUND(100*AVG(pd_esc1_base),3)           AS esc1_base,
  ROUND(100*AVG(pd_esc2_fen70),3)          AS esc2_fen70,
  ROUND(100*AVG(pd_esc3_macropes),3)       AS esc3_macropes,
  ROUND(100*AVG(pd_esc4_macropes_fen50),3) AS esc4_pes_fen50,
  MIN(punt_esc4_macropes_fen50) AS min_punt_esc4, MAX(punt_esc1_base) AS max_punt_esc1
FROM disc_model_owner.fen_pd_escenarios_2609