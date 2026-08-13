-- ============================================================================
-- V16. EL ARQUETIPO DE SALUD SOBREVIVE AL FIJAR LA LINEA
--   scan: __T___cal, flg_calib = 1 y flg_clean = 1, desde 202307
--   ancla: v14 comparo los ejes MARGINALMENTE. El arquetipo dio ratio 0.548 a 0.691,
--          o sea 1.26 veces, contra 2.6 de la linea, y su rd sube junto con la pd, lo
--          que sugiere que el score ya lo capturo. Pero el test correcto es fijar la
--          linea y ver si sobrevive, igual que se hizo con el nodo
--   se recorta a 202307 en adelante porque t_inca_sa arranca en 202305 y antes el
--          SIN_DATO es un artefacto temporal, no un tipo de cliente
-- ============================================================================
WITH b AS (
    SELECT CASE WHEN ctrl_solo_linea = 1 THEN '1.solo linea'
                ELSE                          '2.con saldo' END                         AS linea,
           coalesce(seg_arq_salud, 'SIN_DATO')                                          AS salud,
           CASE WHEN entidad = '00002' THEN '1.IBK' ELSE '2.resto' END                  AS ambito,
           target_12m,
           pd_raw
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal
    WHERE flg_calib = 1 AND flg_clean = 1
      AND codmes_mrm >= '202307'
)
SELECT ambito,
       CASE WHEN GROUPING(linea) = 1 THEN 'T.todas' ELSE linea END                      AS linea,
       CASE WHEN GROUPING(salud) = 1 THEN 'T.todos' ELSE salud END                      AS salud,
       count(*)                                                                         AS n,
       sum(target_12m)                                                                  AS n_malo,
       round(100.0 * avg(CAST(target_12m AS DOUBLE)), 4)                                AS rd_12m,
       round(100.0 * avg(pd_raw), 4)                                                    AS pd_raw_media,
       round(avg(CAST(target_12m AS DOUBLE)) / nullif(avg(pd_raw), 0), 4)               AS ratio_obs_pred
FROM b
GROUP BY GROUPING SETS ((ambito, linea, salud), (ambito, linea), (ambito, salud))
ORDER BY ambito, linea, salud
LIMIT 60
