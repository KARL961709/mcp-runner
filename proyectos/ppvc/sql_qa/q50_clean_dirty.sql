-- ============================================================================
-- q50. Calce clean vs dirty (valida el overlay dirty): prob del producto propio
--      vs RD real, por sub_producto x flg_clean, pooled ventana madura.
-- ============================================================================
WITH s AS (
  SELECT sub_producto, flg_clean, COUNT(*) AS n_s,
         AVG(CASE WHEN sub_producto = 'PP_FACIL' THEN prob_modelo_ppfacil ELSE prob_modelo_ppcd END) AS pd_media
  FROM disc_model_owner.scr_ppvc_cal
  WHERE sub_producto IN ('PP_FACIL', 'PP_CD') AND codmes BETWEEN '202311' AND '202507'
  GROUP BY sub_producto, flg_clean
),
r AS (
  SELECT sub_producto, flg_clean, COUNT(*) AS n_r, SUM(target_12m) AS malos, AVG(target_12m) AS rd_real
  FROM disc_model_owner.ds_adm_pp_cdpp_cal
  WHERE flg_calib = 1 AND pd_raw IS NOT NULL AND target_12m IS NOT NULL
    AND sub_producto IN ('PP_FACIL', 'PP_CD') AND codmes BETWEEN '202311' AND '202507'
  GROUP BY sub_producto, flg_clean
)
SELECT s.sub_producto, s.flg_clean, r.n_r AS n, CAST(r.malos AS integer) AS malos,
  ROUND(s.pd_media, 4) AS pd_media,
  ROUND(r.rd_real, 4) AS rd_real,
  ROUND(s.pd_media / NULLIF(r.rd_real, 0) - 1, 3) AS ec
FROM s JOIN r ON s.sub_producto = r.sub_producto AND s.flg_clean = r.flg_clean
ORDER BY s.sub_producto, s.flg_clean
