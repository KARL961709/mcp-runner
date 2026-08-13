-- ============================================================================
-- V1. AFP - RANGO, VOLUMEN Y CUANTOS COBRARON DE VERDAD
--   scan: e_perm_aws.t_fact_edc_solicitud_retiro_afp_ibk por anio de ts_solicitud
--   ancla: solicitar no es cobrar. El create original excluye a todo el que pidio, sin
--          mirar flg_abono ni el estado. Y sin fecha la exclusion seria look-ahead
-- ============================================================================
SELECT CAST(year(ts_solicitud) AS VARCHAR)                                              AS anio,
       count(*)                                                                         AS n_solicitudes,
       count(DISTINCT key_value)                                                        AS n_personas,
       sum(CAST(flg_abono AS INTEGER))                                                  AS n_con_abono,
       round(100.0 * avg(CAST(flg_abono AS DOUBLE)), 3)                                 AS pct_con_abono,
       round(avg(CASE WHEN flg_abono = 1 THEN mto_abono END), 0)                        AS mto_medio_abonado,
       count(DISTINCT desc_estado_solicitud)                                            AS n_estados,
       min(CAST(ts_solicitud AS VARCHAR))                                               AS ts_min,
       max(CAST(ts_solicitud AS VARCHAR))                                               AS ts_max
FROM e_perm_aws.t_fact_edc_solicitud_retiro_afp_ibk
GROUP BY CAST(year(ts_solicitud) AS VARCHAR)
ORDER BY anio
