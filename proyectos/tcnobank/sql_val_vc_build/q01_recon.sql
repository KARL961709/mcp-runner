-- ============================================================================
-- Q01. RECONCILIACION DEL ENSAMBLE
--   El LEFT JOIN de 53 no puede abrir filas: 51_dmsf agrega por cliente y mes,
--   y 52 hereda el grano de 11_po_key, que es el mismo de cal.
--   n_cal y n_cal_vc tienen que ser identicos y n_dup tiene que ser cero.
-- ============================================================================
SELECT (SELECT count(*) FROM disc_model_owner.ds_adm_vcnbank_tc_cal)            AS n_cal,
       (SELECT count(*) FROM disc_model_owner.ds_adm_vcnbank_tc_cal_vc)         AS n_cal_vc,
       (SELECT count(*) FROM ( SELECT tip_doc, id_value, entidad, codmes_mrm
                                 FROM disc_model_owner.ds_adm_vcnbank_tc_cal_vc
                                GROUP BY tip_doc, id_value, entidad, codmes_mrm
                               HAVING count(*) > 1 ) z)                         AS n_dup,
       (SELECT count(*) FROM disc_model_owner.ds_adm_vcnbank_tc_cal_vc
         WHERE target_vc_12m IS NULL AND falla_madurez_vc = 0)                  AS n_null_maduro,
       (SELECT count(*) FROM disc_model_owner.ds_adm_vcnbank_tc_cal_vc
         WHERE max_dm_sf_fut IS NULL)                                           AS n_sin_dmsf
