-- 01. FRONTERA DE DS_ADM_VCNBANK_TC_CAL
--   hasta que mes hay FILAS, no particiones declaradas. Cuenta, no max():
--   una particion vacia declara un mes que no existe (regla E1)
SELECT codmes_mrm AS codmes,
       COUNT(*)                                                             AS n_filas,
       COUNT(DISTINCT id_value) AS n_personas
  FROM disc_model_owner.ds_adm_vcnbank_tc_cal
 WHERE CAST(codmes_mrm AS VARCHAR) >= '202512'
 GROUP BY codmes_mrm
 ORDER BY 1
