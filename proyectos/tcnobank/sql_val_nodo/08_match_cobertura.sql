-- 08. QUE FILAS DEL CSV NO CRUZAN
--   Localmente se midio que las 2,013 que no cruzan lo hacen por CODMES y no
--   por llave: el id existe en todas. Aca se separa una cosa de la otra, que es
--   lo que distingue un problema de poblacion de uno de formato de llave
SELECT COUNT(*)                                                                  AS n_csv,
       SUM(CASE WHEN d.id_value IS NOT NULL THEN 1 ELSE 0 END)                   AS cruzan_llave_y_mes,
       SUM(CASE WHEN d.id_value IS NULL AND e.id_value IS NOT NULL
                THEN 1 ELSE 0 END)                                               AS solo_falla_el_mes,
       SUM(CASE WHEN d.id_value IS NULL AND e.id_value IS NULL
                THEN 1 ELSE 0 END)                                               AS llave_inexistente
  FROM disc_model_owner.aux_nodos_recibido c
  LEFT JOIN disc_model_owner.ds_adm_vcnbank_tc_cal d
         ON d.tip_doc = c.tip_doc AND d.id_value = c.key_value
        AND d.codmes_mrm = c.codmes AND d.entidad = '00002'
  LEFT JOIN (SELECT DISTINCT tip_doc, id_value
               FROM disc_model_owner.ds_adm_vcnbank_tc_cal
              WHERE entidad = '00002') e
         ON e.tip_doc = c.tip_doc AND e.id_value = c.key_value
