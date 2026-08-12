-- ============================================================================
-- 90. RECONCILIACION DE FLG_CLEAN Y DOMINIO DE FLG_CALIB
-- ============================================================================
SELECT 'G1' AS gate, chk, n_viol, n_magnitud,
       CASE WHEN n_viol = 0 THEN 'PASS' ELSE 'FAIL' END AS veredicto
FROM (
    SELECT 'meses donde 99 + 1 + 0 no suma el universo' AS chk,
           sum(CASE WHEN n_tot <> n99 + n1 + n0 THEN 1 ELSE 0 END) AS n_viol,
           sum(n_tot) AS n_magnitud
    FROM (SELECT codmes_mrm, count(*) AS n_tot,
                 sum(CASE WHEN flg_clean = 99 THEN 1 ELSE 0 END) AS n99,
                 sum(CASE WHEN flg_clean = 1  THEN 1 ELSE 0 END) AS n1,
                 sum(CASE WHEN flg_clean = 0  THEN 1 ELSE 0 END) AS n0
          FROM disc_model_owner.ds_adm_vcnbank_tc_cal GROUP BY codmes_mrm) x
    UNION ALL
    SELECT 'flg_clean fuera de 99, 1 y 0',
           sum(CASE WHEN flg_clean NOT IN (99,1,0) OR flg_clean IS NULL THEN 1 ELSE 0 END),
           count(*) FROM disc_model_owner.ds_adm_vcnbank_tc_cal
    UNION ALL
    SELECT 'flg_calib fuera de 0 y 1',
           sum(CASE WHEN flg_calib NOT IN (0,1) OR flg_calib IS NULL THEN 1 ELSE 0 END),
           count(*) FROM disc_model_owner.ds_adm_vcnbank_tc_cal
    UNION ALL
    SELECT 'flg_hist fuera de 0 y 1',
           sum(CASE WHEN flg_hist NOT IN (0,1) OR flg_hist IS NULL THEN 1 ELSE 0 END),
           count(*) FROM disc_model_owner.ds_adm_vcnbank_tc_cal
    UNION ALL
    SELECT 'flg_calib = 1 con flg_hist = 0',
           sum(CASE WHEN flg_calib = 1 AND flg_hist = 0 THEN 1 ELSE 0 END),
           count(*) FROM disc_model_owner.ds_adm_vcnbank_tc_cal
    UNION ALL
    SELECT 'llaves duplicadas en el maestro',
           (SELECT count(*) FROM (SELECT codmes_mrm, tip_doc, id_value, entidad
                                  FROM disc_model_owner.ds_adm_vcnbank_tc_cal GROUP BY 1,2,3,4 HAVING count(*) > 1) d),
           count(*) FROM disc_model_owner.ds_adm_vcnbank_tc_cal
    UNION ALL
    SELECT 'clientes con mas de una prelacion_cod = 1',
           (SELECT count(*) FROM (SELECT codmes_mrm, tip_doc, id_value FROM disc_model_owner.ds_adm_vcnbank_tc_cal
                                  WHERE prelacion_cod = 1 GROUP BY 1,2,3 HAVING count(*) > 1) p),
           count(*) FROM disc_model_owner.ds_adm_vcnbank_tc_cal WHERE prelacion_cod = 1
) y
