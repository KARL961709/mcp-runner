-- ============================================================================
-- V17. N3 POR COMPORTAMIENTO CONTRA N3 POR FALTA DE DATO
--   scan: __T___cal, entidad 00002, flg_calib = 1 y flg_clean = 1, desde 202307
--   ancla: el nvl(...,0) del nodo convierte el hueco en cero, asi que N3 tiene 59.3
--          por ciento sin PLIN y 84.0 sin fila de cuenta sueldo. Esa gente cae en N3
--          por falta de dato, no por comportamiento. Si el ratio difiere entre los dos
--          grupos, el nodo esta fundiendo dos poblaciones
--   y se cruza contra el arquetipo, que es el unico eje disponible para los que no
--          tienen ni PLIN ni cuenta sueldo
-- ============================================================================
WITH b AS (
    SELECT nodo_final                                                                   AS nodo,
           CASE WHEN ctrl_sin_plin = 1 AND ctrl_sin_cta_sueldo = 1 THEN '3.sin ninguno'
                WHEN ctrl_sin_plin = 1 OR  ctrl_sin_cta_sueldo = 1 THEN '2.sin uno'
                ELSE                                                    '1.con los dos' END AS datos,
           coalesce(seg_arq_salud, 'SIN_DATO')                                          AS salud,
           target_12m,
           pd_raw
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal
    WHERE flg_calib = 1 AND flg_clean = 1
      AND entidad = '00002'
      AND codmes_mrm >= '202307'
)
SELECT nodo,
       CASE WHEN GROUPING(datos) = 1 THEN 'T.todos' ELSE datos END                      AS datos,
       CASE WHEN GROUPING(salud) = 1 THEN 'T.todos' ELSE salud END                      AS salud,
       count(*)                                                                         AS n,
       sum(target_12m)                                                                  AS n_malo,
       round(100.0 * avg(CAST(target_12m AS DOUBLE)), 4)                                AS rd_12m,
       round(100.0 * avg(pd_raw), 4)                                                    AS pd_raw_media,
       round(avg(CAST(target_12m AS DOUBLE)) / nullif(avg(pd_raw), 0), 4)               AS ratio_obs_pred
FROM b
GROUP BY GROUPING SETS ((nodo, datos), (nodo, salud), (nodo))
ORDER BY nodo, datos, salud
LIMIT 60
