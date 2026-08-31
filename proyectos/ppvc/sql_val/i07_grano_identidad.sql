-- ============================================================================
-- i07. GRANO e IDENTIDAD: duplicados por (codmes,tip_doc,key_value) via conteo
--   distinto (NO sale detalle), identidad del universo (99+1+0) y dominio de
--   flags. READ-ONLY, una sola fila.
-- ============================================================================
SELECT
  count(*)                                                                        AS n_total,
  count(*) - count(DISTINCT codmes || '|' || tip_doc || '|' || key_value)         AS n_dup,
  sum(CASE WHEN flg_clean = 99 THEN 1 ELSE 0 END)                                 AS n_99,
  sum(CASE WHEN flg_clean = 1  THEN 1 ELSE 0 END)                                 AS n_1,
  sum(CASE WHEN flg_clean = 0  THEN 1 ELSE 0 END)                                 AS n_0,
  sum(CASE WHEN flg_clean NOT IN (0,1,99) OR flg_clean IS NULL THEN 1 ELSE 0 END) AS n_clean_raro,
  sum(CASE WHEN flg_calib NOT IN (0,1) OR flg_calib IS NULL THEN 1 ELSE 0 END)    AS n_calib_raro
FROM disc_model_owner.ds_adm_pp_cdpp_cal
