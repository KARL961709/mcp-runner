-- ============================================================================
-- V18. LA ZONA SIN DATOS DENTRO DE CADA NODO
--   scan: __T___cal, entidad 00002, flg_calib = 1 y flg_clean = 1
--   ancla: el nvl(...,0) del nodo mete al que no tiene dato en el mismo nivel que al
--          que tiene dato y da cero. v17 partio por PLIN y cuenta sueldo pero dejo
--          fuera el 360. Aca entran las tres, y el caso extremo es sin ninguna de las
--          tres: ese es el prospecto de campania sin huella en el banco
--   si su ratio difiere del resto de su nodo, la LRA de ese nodo no lo representa
-- ============================================================================
WITH b AS (
    SELECT nodo_final                                                                   AS nodo,
           ctrl_sin_plin + ctrl_sin_cta_sueldo + ctrl_sin_360                           AS n_fuentes_sin,
           CASE WHEN ctrl_sin_plin = 1 AND ctrl_sin_cta_sueldo = 1 AND ctrl_sin_360 = 1
                THEN '4.sin ninguna de las tres'
                WHEN ctrl_sin_plin + ctrl_sin_cta_sueldo + ctrl_sin_360 = 2
                THEN '3.sin dos'
                WHEN ctrl_sin_plin + ctrl_sin_cta_sueldo + ctrl_sin_360 = 1
                THEN '2.sin una'
                ELSE '1.con las tres' END                                               AS huella,
           target_12m,
           pd_raw
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal
    WHERE flg_calib = 1 AND flg_clean = 1
      AND entidad = '00002'
)
SELECT nodo,
       CASE WHEN GROUPING(huella) = 1 THEN 'T.todos' ELSE huella END                    AS huella,
       count(*)                                                                         AS n,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY nodo), 3)              AS pct_del_nodo,
       sum(target_12m)                                                                  AS n_malo,
       round(100.0 * avg(CAST(target_12m AS DOUBLE)), 4)                                AS rd_12m,
       round(100.0 * avg(pd_raw), 4)                                                    AS pd_raw_media,
       round(avg(CAST(target_12m AS DOUBLE)) / nullif(avg(pd_raw), 0), 4)               AS ratio_obs_pred
FROM b
GROUP BY GROUPING SETS ((nodo, huella), (nodo))
ORDER BY nodo, huella
LIMIT 30
