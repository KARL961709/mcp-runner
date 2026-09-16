-- q02 clasif vs cascada POR GRUPO de corte (puntuacion_modelo_cal_ppfacil: 985/955/947/912/892/864). PD por banda, flips a dirty, migracion de grupo. 202401. Read-only.
WITH j AS (
  SELECT
    s.puntuacion_modelo_cal_ppfacil AS punt_cl, c.puntuacion_modelo_cal_ppfacil AS punt_ca,
    s.prob_modelo_cal_ppfacil AS pd_cl, c.prob_modelo_cal_ppfacil AS pd_ca,
    s.flg_clean AS clean_cl, c.flg_clean AS clean_ca
  FROM disc_model_owner.scr_admvc_pp_cal_202401_202606 s
  JOIN disc_model_owner.scr_admvc_pp_cal_202401_202606_casc c
    ON c.codmes = s.codmes AND c.key_value = s.key_value AND c.cod_tip_doc = s.cod_tip_doc
),
g AS (
  SELECT j.*,
    CASE WHEN punt_cl >= 985 THEN 'G1' WHEN punt_cl >= 955 THEN 'G2' WHEN punt_cl >= 947 THEN 'G3' WHEN punt_cl >= 912 THEN 'G4' WHEN punt_cl >= 892 THEN 'G5' WHEN punt_cl >= 864 THEN 'G6' ELSE 'GR' END AS grp_cl,
    CASE WHEN punt_ca >= 985 THEN 'G1' WHEN punt_ca >= 955 THEN 'G2' WHEN punt_ca >= 947 THEN 'G3' WHEN punt_ca >= 912 THEN 'G4' WHEN punt_ca >= 892 THEN 'G5' WHEN punt_ca >= 864 THEN 'G6' ELSE 'GR' END AS grp_ca
  FROM j
)
SELECT grp_cl,
  COUNT(*) AS n,
  round(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_n,
  round(AVG(pd_cl) * 100, 3) AS pd_clasif_pct,
  round(AVG(pd_ca) * 100, 3) AS pd_casc_pct,
  round(AVG(pd_ca - pd_cl) * 100, 4) AS d_pd_pct,
  SUM(CASE WHEN clean_cl = 1 AND clean_ca = 0 THEN 1 ELSE 0 END) AS n_flip_dirty,
  SUM(CASE WHEN grp_cl <> grp_ca THEN 1 ELSE 0 END) AS n_migra_grupo
FROM g
GROUP BY grp_cl
ORDER BY grp_cl
