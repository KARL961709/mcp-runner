-- ============================================================================
-- v47. IMPACTO del congelamiento, mes a mes. Read-only, no escribe nada.
--
--   GENERADA por 32_genera_sql_ftfreeze.py en la misma corrida que el CTAS.
--
--   Sale de UNA sola tabla: la congelada ya trae el f_t del mes al lado del
--   congelado, asi que no hace falta leer la viva ni cruzar por llave.
--
--   QUE MIRAR:
--     ft_v2_mes vs ft_v2_fz  la brecha de macro. En 202609 debe ser 0.
--     pd_v2_media_pct        la PD que entrega esta tabla.
--     delta_pp               cuanto movio el congelamiento ese mes, en puntos
--                            porcentuales de PD. Signo positivo = la tabla
--                            congelada pide MAS PD que la viva.
--   El f_t es un corrimiento comun dentro del mes, asi que delta_pp mueve el
--   NIVEL y no el ordenamiento: el ranking del mes es identico al de la viva.
--
--   Ventana recortada a 202506 en adelante a proposito: son los meses de la
--   aplicacion, y asi la salida cabe en pocas filas.
-- ============================================================================
WITH fz AS (
  SELECT CAST(codmes AS VARCHAR)            AS codmes,
         CAST(trf_f_t_v2 AS DOUBLE)         AS ft_fz,
         CAST(trf_f_t_v2_mes AS DOUBLE)     AS ft_mes,
         CAST(prob_modelo_cal_v2 AS DOUBLE) AS pd_fz
  FROM disc_model_owner.scr_stk_ree_pp_cal_v1v2_ftfz2609
  WHERE CAST(codmes AS VARCHAR) >= '202506'
),
vv AS (
  SELECT CAST(codmes AS VARCHAR)            AS codmes,
         AVG(CAST(prob_modelo_cal_v2 AS DOUBLE)) AS pd_vv
  FROM disc_model_owner.scr_stk_ree_pp_cal_v1v2
  WHERE CAST(codmes AS VARCHAR) >= '202506'
  GROUP BY CAST(codmes AS VARCHAR)
)
SELECT f.codmes,
       COUNT(*)                                             AS n,
       ROUND(MAX(f.ft_mes), 8)                              AS ft_v2_mes,
       ROUND(MAX(f.ft_fz), 8)                               AS ft_v2_fz,
       ROUND(MAX(f.ft_fz) - MAX(f.ft_mes), 8)               AS ft_delta,
       ROUND(100.0 * AVG(f.pd_fz), 6)                       AS pd_v2_media_pct,
       ROUND(100.0 * MAX(v.pd_vv), 6)                       AS pd_v2_viva_pct,
       ROUND(100.0 * (AVG(f.pd_fz) - MAX(v.pd_vv)), 6)      AS delta_pp,
       ROUND(100.0 * (AVG(f.pd_fz) / NULLIF(MAX(v.pd_vv), 0) - 1.0), 4) AS delta_rel_pct
FROM fz f
LEFT JOIN vv v ON v.codmes = f.codmes
GROUP BY f.codmes
ORDER BY 1
