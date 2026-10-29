-- ============================================================================
-- v28. PRIMER MES REAL de las dos fuentes candidatas, contando filas
--   Discrimina el ancla del master. Su pd arranca en 202212 con cobertura 100
--   pct, y eso es compatible con dos cosas distintas:
--     A  ancla codmes_scr (+1) sobre una fuente que arranca en 202301
--     B  ancla codmes_mrm      sobre una fuente que arranca en 202212
--   El nombre de la tabla nueva dice 2023 y su comentario declara 202301, pero
--   declarado no es observado: se cuenta.
-- ============================================================================
SELECT 'cal_2023 (fuente nueva)'              AS fuente,
       CAST(cod_mes AS VARCHAR)               AS mes,
       COUNT(*)                               AS n_filas,
       COUNT(prob_modelo)                     AS n_pd_no_nulo,
       COUNT(DISTINCT CAST(key_value AS VARCHAR)) AS n_llaves
  FROM disc_model_owner.scr_stk_ree_pp_cal_2023_202610
 WHERE CAST(cod_mes AS VARCHAR) <= '202306'
 GROUP BY CAST(cod_mes AS VARCHAR)
UNION ALL
SELECT 'reen_v4 (fuente vieja)'               AS fuente,
       CAST(codmes AS VARCHAR),
       COUNT(*),
       COUNT(pd_comppp_reen_itc),
       COUNT(DISTINCT CAST(key_value AS VARCHAR))
  FROM disc_riesgos.t_b39918_scr_stockpp_itc_reen_reprocesov4
 WHERE CAST(codmes AS VARCHAR) <= '202306'
 GROUP BY CAST(codmes AS VARCHAR)
ORDER BY 1, 2
