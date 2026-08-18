-- 06. QUE EL CRUCE SEA 1 A 1
--   n_scr = n_join prueba que el INNER JOIN no perdio ni abrio filas. Si
--   n_join sale mayor, el grano se rompio y hay que revisar las cuatro
--   columnas de la llave antes de creerle a cualquier promedio del cruce
SELECT (SELECT COUNT(*) FROM disc_model_owner.scr_adm_vcnbank_tc_cal)            AS n_scr,
       (SELECT COUNT(*) FROM disc_model_owner.ds_adm_vcnbank_tc_cal)             AS n_ds,
       (SELECT COUNT(*)
          FROM disc_model_owner.scr_adm_vcnbank_tc_cal s
          INNER JOIN disc_model_owner.ds_adm_vcnbank_tc_cal d
                  ON d.tip_doc    = s.tip_doc
                 AND d.id_value   = s.id_value
                 AND d.entidad    = s.entidad
                 AND d.codmes_mrm = s.codmes_mrm)                                AS n_join_4_llaves,
       (SELECT COUNT(*)
          FROM disc_model_owner.scr_adm_vcnbank_tc_cal s
          INNER JOIN disc_model_owner.ds_adm_vcnbank_tc_cal d
                  ON d.tip_doc    = s.tip_doc
                 AND d.id_value   = s.id_value
                 AND d.codmes_mrm = s.codmes_mrm)                                AS n_join_sin_entidad
