-- ============================================================================
-- D26. CONTRA QUE CORTE NUESTRO EMPATA EL CSV DE NODOS
--   scan: ds_adm_vcnbank_tc_cal, entidad 00002, [202410,202504]
--   ancla: el csv trae 2,666 por mes de IBK con la cascada completa (BUENO MALO
--          INSUFICIENTE INDETERMINADO). Si ninguno de nuestros cortes da ese numero,
--          el csv es una muestra y no la poblacion, y no sirve como referencia de nivel
-- ============================================================================
SELECT codmes_mrm,
       count(*)                                                                         AS universo,
       sum(CASE WHEN flg_clean <> 99 THEN 1 ELSE 0 END)                                 AS no_scope,
       sum(CASE WHEN flg_clean = 1 THEN 1 ELSE 0 END)                                   AS clean,
       sum(CASE WHEN flg_calib = 1 AND flg_clean = 1 THEN 1 ELSE 0 END)                 AS calib_clean,
       sum(CASE WHEN prelacion_cod = 1 AND flg_clean <> 99 THEN 1 ELSE 0 END)           AS no_scope_prel1,
       sum(CASE WHEN prelacion_cod = 1 AND flg_calib = 1 AND flg_clean = 1
                THEN 1 ELSE 0 END)                                                      AS calib_clean_prel1,
       round(100.0 * avg(CASE WHEN flg_calib = 1 AND flg_clean = 1
                              THEN CAST(target_12m AS DOUBLE) END), 4)                  AS rd_calib,
       round(100.0 * avg(CASE WHEN flg_clean <> 99
                              THEN CAST(target_12m AS DOUBLE) END), 4)                  AS rd_no_scope
FROM disc_model_owner.ds_adm_vcnbank_tc_cal
WHERE entidad = '00002'
  AND codmes_mrm BETWEEN '202410' AND '202504'
GROUP BY codmes_mrm
ORDER BY codmes_mrm
