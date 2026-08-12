-- ============================================================================
-- 86. LA REGLA DE LINEA NO PUEDE MATAR UNA ENTIDAD ENTERA
--   scan: disc_model_owner.ds_adm_vcnbank_tc_cal por entidad y anio
--   ancla: medido solo en BCP y BBVA, donde las altas reales sin linea son 191 de
--          909,588 y 93 de 1,085,687. Si una entidad no reporta 81-923 la regla le
--          borra toda la poblacion: eso es falla, no filtro
-- ============================================================================
SELECT 'G23' AS gate,
       entidad,
       substr(codmes_mrm, 1, 4)                                                         AS anio,
       count(*)                                                                         AS n_magnitud,
       sum(f_sin_linea)                                                                 AS n_viol,
       round(100.0 * avg(CAST(f_sin_linea AS DOUBLE)), 3)                               AS pct_sin_linea,
       round(100.0 * avg(CASE WHEN f_sin_linea = 0
                              THEN CAST(target_12m AS DOUBLE) END), 4)                  AS rd_con_linea,
       round(100.0 * avg(CASE WHEN f_sin_linea = 1
                              THEN CAST(target_12m AS DOUBLE) END), 4)                  AS rd_sin_linea,
       CASE WHEN avg(CAST(f_sin_linea AS DOUBLE)) > 0.25 THEN 'FAIL' ELSE 'PASS' END    AS veredicto
FROM disc_model_owner.ds_adm_vcnbank_tc_cal
WHERE entidad IN ('00001','00002','00004','00006','00142')
GROUP BY entidad, substr(codmes_mrm, 1, 4)
ORDER BY entidad, anio
