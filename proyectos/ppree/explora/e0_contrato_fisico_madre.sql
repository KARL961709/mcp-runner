-- ============================================================================
-- E0. CONTRATO FISICO DE LA MADRE (tipo, padding, trim, dominio de llaves)
-- ============================================================================
SELECT
  'enr_ds_flg_compppibk_rsk'                                        AS tabla,
  COUNT(*)                                                          AS n,
  typeof(MIN(codmes_mrm))                                           AS t_codmes_mrm,
  typeof(MIN(tip_doc))                                              AS t_tip_doc,
  typeof(MIN(id_value))                                             AS t_id_value,
  typeof(MIN(nro_dm_m01))                                           AS t_nro_dm,
  typeof(MIN(dsc_flg_malo_12m))                                     AS t_dsc_flg,
  MIN(LENGTH(CAST(codmes_mrm AS VARCHAR)))                          AS len_min_codmes,
  MAX(LENGTH(CAST(codmes_mrm AS VARCHAR)))                          AS len_max_codmes,
  MIN(LENGTH(CAST(id_value AS VARCHAR)))                            AS len_min_key,
  MAX(LENGTH(CAST(id_value AS VARCHAR)))                            AS len_max_key,
  SUM(CASE WHEN LENGTH(CAST(id_value AS VARCHAR)) <> LENGTH(TO_UTF8(CAST(id_value AS VARCHAR))) THEN 1 ELSE 0 END) AS n_key_no_ascii,
  SUM(CASE WHEN CAST(id_value AS VARCHAR) <> TRIM(CAST(id_value AS VARCHAR)) THEN 1 ELSE 0 END)                    AS n_key_con_espacios,
  SUM(CASE WHEN SUBSTR(CAST(id_value AS VARCHAR), 1, 1) = '0' THEN 1 ELSE 0 END)                                   AS n_key_con_ceros,
  COUNT(DISTINCT CAST(tip_doc AS VARCHAR))                          AS n_dom_tip_doc,
  COUNT(DISTINCT dsc_flg_malo_12m)                                  AS n_dom_dsc_12m,
  COUNT(DISTINCT dsc_flg_malo_12m_v2)                               AS n_dom_dsc_12m_v2,
  SUM(CASE WHEN dsc_flg_malo_12m IS NULL THEN 1 ELSE 0 END)         AS n_dsc_12m_null,
  MIN(nro_dm_m00)                                                   AS dm00_min,
  MAX(nro_dm_m00)                                                   AS dm00_max,
  MIN(max_dm_12m)                                                   AS dm12_min,
  MAX(max_dm_12m)                                                   AS dm12_max
FROM disc_model_owner.enr_ds_flg_compppibk_rsk
