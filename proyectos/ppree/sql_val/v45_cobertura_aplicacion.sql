-- ============================================================================
-- v45. COBERTURA de la ventana de aplicacion, mes a mes.
--
--   GENERADA por 31_genera_sql_v2platt.py. Read-only, no escribe nada.
--
--   POR QUE EXISTE. v43 corre sobre la ventana de AJUSTE y no ve los meses
--   posteriores. La cadena de V2 usa MA3 lag 0, que pide el mes corriente: si
--   porc_ipc de t_mst_bcrp_rsk no alcanza un mes, el HAVING COUNT(yy) = 3 lo
--   deja sin f_t y prob_modelo_cal_v2 sale NULL SIN ERROR. Un NULL silencioso
--   en el ultimo mes es justo lo que no se puede descubrir en produccion.
--
--   QUE MIRAR, en este orden:
--     n_pd_v2_null  debe ser 0 en TODOS los meses. Si el ultimo mes trae nulos,
--                   porc_ipc no llego hasta ahi.
--     f_t_v2        debe moverse mes a mes y NO ser NULL. Valores esperados
--                   segun la macro observada: ~ -0.0304 (en el piso del cap) de
--                   202510 a 202601, y subiendo de 202602 en adelante hasta
--                   ~ +0.10 / +0.12 en 202608-202610.
--     macro_fuente  'BCRP' en todo. Si apareciera otra cosa hay un override vivo.
--     pd_v2_media   sube con f_t: es el efecto del overlay, no un defecto.
-- ============================================================================
SELECT CAST(codmes AS VARCHAR)                                     AS codmes,
       COUNT(*)                                                    AS n,
       SUM(CASE WHEN prob_modelo_cal_v2 IS NULL THEN 1 ELSE 0 END) AS n_pd_v2_null,
       SUM(CASE WHEN prob_modelo_cal_v1 IS NULL THEN 1 ELSE 0 END) AS n_pd_v1_null,
       SUM(CASE WHEN trf_tipo_ingreso_dep IS NULL THEN 1 ELSE 0 END) AS n_celda_null,
       MAX(CAST(trf_macro_fuente AS VARCHAR))                      AS macro_fuente,
       ROUND(MAX(CAST(trf_f_t_v2 AS DOUBLE)), 8)                   AS f_t_v2,
       ROUND(MAX(CAST(trf_f_t_v1 AS DOUBLE)), 8)                   AS f_t_v1,
       ROUND(100.0 * AVG(CAST(prob_modelo_cal_v2 AS DOUBLE)), 6)   AS pd_v2_media_pct,
       ROUND(100.0 * AVG(CAST(prob_modelo_cal_v1 AS DOUBLE)), 6)   AS pd_v1_media_pct,
       ROUND(100.0 * MIN(CAST(prob_modelo_cal_v2 AS DOUBLE)), 6)   AS pd_v2_min_pct,
       ROUND(100.0 * MAX(CAST(prob_modelo_cal_v2 AS DOUBLE)), 6)   AS pd_v2_max_pct
FROM disc_model_owner.scr_stk_ree_pp_cal_v1v2
GROUP BY CAST(codmes AS VARCHAR)
ORDER BY 1
