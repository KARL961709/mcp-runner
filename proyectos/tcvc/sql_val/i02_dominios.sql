-- i02. E0 dominios y nulls de columnas clave (un solo row resumen).
SELECT
  COUNT(*) AS n,
  COUNT(DISTINCT flg_clean) AS d_clean, COUNT(DISTINCT flg_ibk) AS d_ibk, COUNT(DISTINCT flg_calib) AS d_calib,
  COUNT(DISTINCT tipo_ingreso) AS d_tping, COUNT(DISTINCT nodo) AS d_nodo,
  ROUND(MIN(pd_raw), 6) AS pd_min, ROUND(MAX(pd_raw), 6) AS pd_max,
  SUM(CASE WHEN pd_raw IS NULL THEN 1 ELSE 0 END) AS pd_null,
  SUM(CASE WHEN tipo_ingreso IS NULL THEN 1 ELSE 0 END) AS tping_null,
  SUM(CASE WHEN nodo IS NULL THEN 1 ELSE 0 END) AS nodo_null
FROM disc_model_owner.ds_adm_tcbank_cal