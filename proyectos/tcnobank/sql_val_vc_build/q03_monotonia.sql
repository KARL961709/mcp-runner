-- ============================================================================
-- Q03. MONOTONIA POR HORIZONTE Y MADUREZ
--   target_vc_01m <= ... <= target_vc_12m fila por fila: n_no_monotono = 0.
--   Y el horizonte corto compra ventana, asi que n_mad_NN no puede bajar.
-- ============================================================================
SELECT codmes_mrm                                                               AS codmes,
       count(*)                                                                 AS n,
       sum(CASE WHEN coalesce(target_vc_01m,0) > coalesce(target_vc_03m,1)
                  OR coalesce(target_vc_03m,0) > coalesce(target_vc_06m,1)
                  OR coalesce(target_vc_06m,0) > coalesce(target_vc_09m,1)
                  OR coalesce(target_vc_09m,0) > coalesce(target_vc_12m,1)
                THEN 1 ELSE 0 END)                                              AS n_no_monotono,
       sum(CASE WHEN target_vc_03m IS NOT NULL THEN 1 ELSE 0 END)               AS n_mad_03,
       sum(CASE WHEN target_vc_06m IS NOT NULL THEN 1 ELSE 0 END)               AS n_mad_06,
       sum(CASE WHEN target_vc_12m IS NOT NULL THEN 1 ELSE 0 END)               AS n_mad_12,
       avg(CAST(target_vc_12m AS DOUBLE))                                       AS rd_vc_12m,
       avg(CAST(target_12m    AS DOUBLE))                                       AS rd_tc_12m
  FROM disc_model_owner.ds_adm_vcnbank_tc_cal_vc
 WHERE flg_calib = 1 AND flg_clean = 1
 GROUP BY codmes_mrm
 ORDER BY codmes_mrm
