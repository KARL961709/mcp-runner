-- ============================================================================
-- q40. Calce en data del banco: prob del PRODUCTO PROPIO de la fila (matched)
--      vs RD real (target_12m de la fuente), por sub_producto x codmes, madura.
-- ============================================================================
WITH s AS (
  SELECT codmes, sub_producto, COUNT(*) AS n_s,
         AVG(CASE WHEN sub_producto = 'PP_FACIL' THEN prob_modelo_cal_ppfacil ELSE prob_modelo_cal_ppcd END) AS pd_media
  FROM disc_model_owner.scr_ppvc_cal
  WHERE sub_producto IN ('PP_FACIL', 'PP_CD')
  GROUP BY codmes, sub_producto
),
r AS (
  SELECT codmes, sub_producto, COUNT(*) AS n_r, SUM(target_12m) AS malos, AVG(target_12m) AS rd_real
  FROM disc_model_owner.ds_adm_pp_cdpp_cal
  WHERE flg_calib = 1 AND pd_raw IS NOT NULL AND target_12m IS NOT NULL AND sub_producto IN ('PP_FACIL', 'PP_CD')
  GROUP BY codmes, sub_producto
)
SELECT s.sub_producto, s.codmes, r.n_r AS n, CAST(r.malos AS integer) AS malos,
  ROUND(s.pd_media, 4) AS pd_media,
  ROUND(r.rd_real, 4) AS rd_real,
  ROUND(s.pd_media / NULLIF(r.rd_real, 0) - 1, 3) AS ec
FROM s JOIN r ON s.codmes = r.codmes AND s.sub_producto = r.sub_producto
WHERE s.codmes BETWEEN '202311' AND '202507'
ORDER BY s.sub_producto, s.codmes
