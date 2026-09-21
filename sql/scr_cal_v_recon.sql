-- scr_cal_v_recon.sql | RECONCILIACION fuente (e_perm_aws.scr_admbankbpe_rsk) vs tabla calibrada, por p_codmes. src_n_pd - tab_n debe ser 0 (toda pd_raw aplicada), tab_n - tab_n_cal debe ser 0 (toda fila con prob_modelo_cal). Read-only, agregado.
WITH src AS (
  SELECT p_codmes,
         COUNT(*) AS src_n,
         SUM(CASE WHEN probabilidad IS NOT NULL THEN 1 ELSE 0 END) AS src_n_pd
  FROM e_perm_aws.scr_admbankbpe_rsk
  WHERE modelo = 'ADMBANKBPE' AND p_codmes BETWEEN '202501' AND '202608'
  GROUP BY p_codmes
),
tab AS (
  SELECT p_codmes,
         COUNT(*) AS tab_n,
         SUM(CASE WHEN prob_modelo_cal IS NOT NULL THEN 1 ELSE 0 END) AS tab_n_cal
  FROM disc_model_owner.b46029_scr_admbankbpe_cal_202608
  GROUP BY p_codmes
)
SELECT COALESCE(s.p_codmes, t.p_codmes) AS p_codmes,
       s.src_n, s.src_n_pd, t.tab_n, t.tab_n_cal,
       s.src_n_pd - t.tab_n AS diff_pdraw_vs_tabla,
       t.tab_n - t.tab_n_cal AS tabla_sin_cal
FROM src s
FULL OUTER JOIN tab t ON s.p_codmes = t.p_codmes
ORDER BY 1
