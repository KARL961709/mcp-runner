-- 02. EL NODO RECONSTRUIDO CONTRA EL DE LA TABLA
--   en IBK nodo_calc tiene que reproducir nodo_final: n_discrepa = 0.
--   fuera de IBK nodo_final es SIN_ALCANCE, asi que ahi solo se mide de que se
--   alimenta el nodo: pct_sin_ninguna_fuente es la magnitud de la ceguera.
SELECT CASE WHEN entidad = '00002' THEN 'IBK' ELSE 'resto SS.FF.' END             AS grupo,
       COUNT(*)                                                                   AS n,
       SUM(CASE WHEN nodo_calc IS NULL THEN 1 ELSE 0 END)                         AS n_nodo_nulo,
       SUM(CASE WHEN entidad = '00002' AND nodo_calc <> nodo_final
                THEN 1 ELSE 0 END)                                                AS n_discrepa,
       SUM(CASE WHEN ctrl_nodo_observado = 0 THEN 1 ELSE 0 END)                   AS n_sin_ninguna_fuente,
       100.0 * SUM(CASE WHEN ctrl_nodo_observado = 0 THEN 1 ELSE 0 END) / COUNT(*) AS pct_sin_ninguna_fuente,
       AVG(CAST(ctrl_nodo_n_fuentes AS DOUBLE))                                   AS prom_fuentes,
       100.0 * SUM(CASE WHEN nodo_calc = 'N1' THEN 1 ELSE 0 END) / COUNT(*)       AS pct_n1,
       100.0 * SUM(CASE WHEN nodo_calc = 'N2' THEN 1 ELSE 0 END) / COUNT(*)       AS pct_n2,
       100.0 * SUM(CASE WHEN nodo_calc = 'N3' THEN 1 ELSE 0 END) / COUNT(*)       AS pct_n3
  FROM disc_model_owner.scr_adm_vcnbank_tc_cal
 WHERE pd_raw IS NOT NULL
 GROUP BY 1
