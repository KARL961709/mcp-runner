-- ============================================================================
-- 53. TABLA DE CALIBRACION CON EL TARGET VISION CLIENTE PEGADO
--   scan: ds_adm_vcnbank_tc_cal + ds_adm_vcnbank_tc_52_target_vc
--   Aditiva: no toca ds_adm_vcnbank_tc_cal, la copia entera y le suma 15 columnas.
--   LEFT JOIN, asi que sin fila en 52 queda NULL y nunca 0.
--   El grano de 52 es el mismo de cal -tip_doc, id_value, entidad, codmes_mrm-
--   porque los dos salen de 11_po_key, asi que el join no puede abrir filas.
--   Las columnas vc van PRIMERO a proposito: Athena exige que la columna de
--   particion sea la ultima de la proyeccion, y codmes_mrm es la ultima de cal,
--   asi que cerrar con c.* la deja en su lugar sin tener que enumerar cal entera
--   ni romperse si a cal le agregan una columna.
-- ============================================================================
CREATE TABLE disc_model_owner.ds_adm_vcnbank_tc_cal_vc
WITH (format = 'PARQUET', write_compression = 'SNAPPY',
      partitioned_by = ARRAY['codmes_mrm']) AS
SELECT v.max_dm_sf_fut,
       v.missing_12_vc,
       v.falla_madurez_vc,
       v.target_vc_01m, v.target_vc_02m, v.target_vc_03m, v.target_vc_04m,
       v.target_vc_05m, v.target_vc_06m, v.target_vc_07m, v.target_vc_08m,
       v.target_vc_09m, v.target_vc_10m, v.target_vc_11m, v.target_vc_12m,
       c.*
  FROM disc_model_owner.ds_adm_vcnbank_tc_cal c
  LEFT JOIN disc_model_owner.ds_adm_vcnbank_tc_52_target_vc v
         ON v.tip_doc    = c.tip_doc
        AND v.id_value   = c.id_value
        AND v.entidad    = c.entidad
        AND v.codmes_mrm = c.codmes_mrm
