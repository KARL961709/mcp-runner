-- q01 QA reconciliacion por mes: driver opt -> nodos (pd_raw) -> scored (pd cal). Deltas deben ser 0 y n_*_sin_cal = 0 (nada sin calibrar). Read-only. Piloto 202401.
WITH opt AS (
  SELECT codmes, COUNT(*) AS n_opt_dedup FROM (
    SELECT CAST(cod_mes AS varchar) AS codmes, key_value, CAST(cod_tip_doc AS varchar) AS cod_tip_doc,
           ROW_NUMBER() OVER (PARTITION BY cod_mes, key_value, cod_tip_doc ORDER BY prob_model DESC) AS rn
    FROM disc_riesgos.scr_vcbankv3_repro_opt_
    WHERE prob_model IS NOT NULL AND CAST(cod_tip_doc AS varchar) = '1'
      AND CAST(cod_mes AS varchar) BETWEEN '202401' AND '202401'
  ) WHERE rn = 1
  GROUP BY codmes
),
nod AS (
  SELECT CAST(codmes AS varchar) AS codmes, COUNT(*) AS n_nodos,
         SUM(CASE WHEN pd_raw IS NOT NULL THEN 1 ELSE 0 END) AS n_pd_raw
  FROM disc_model_owner.scr_admvc_pp_cal_202401_202606_nodos
  GROUP BY CAST(codmes AS varchar)
),
sco AS (
  SELECT CAST(codmes AS varchar) AS codmes, COUNT(*) AS n_scored,
         SUM(CASE WHEN prob_modelo IS NOT NULL THEN 1 ELSE 0 END) AS n_prob_modelo,
         SUM(CASE WHEN prob_modelo_cal_ppfacil IS NOT NULL THEN 1 ELSE 0 END) AS n_cal_ppfacil,
         SUM(CASE WHEN prob_modelo_cal_ppcd IS NOT NULL THEN 1 ELSE 0 END) AS n_cal_ppcd,
         SUM(CASE WHEN prob_modelo_ttc_ppfacil IS NOT NULL THEN 1 ELSE 0 END) AS n_ttc_ppfacil,
         SUM(CASE WHEN prob_modelo IS NOT NULL AND prob_modelo_cal_ppfacil IS NULL THEN 1 ELSE 0 END) AS n_facil_sin_cal,
         SUM(CASE WHEN prob_modelo IS NOT NULL AND prob_modelo_cal_ppcd IS NULL THEN 1 ELSE 0 END) AS n_ppcd_sin_cal
  FROM disc_model_owner.scr_admvc_pp_cal_202401_202606
  GROUP BY CAST(codmes AS varchar)
)
SELECT COALESCE(o.codmes, n.codmes, s.codmes) AS codmes,
       o.n_opt_dedup, n.n_nodos, n.n_pd_raw, s.n_scored, s.n_prob_modelo,
       s.n_cal_ppfacil, s.n_cal_ppcd, s.n_ttc_ppfacil,
       s.n_facil_sin_cal, s.n_ppcd_sin_cal,
       (o.n_opt_dedup - n.n_nodos) AS d_opt_nodos,
       (n.n_nodos - s.n_scored) AS d_nodos_scored,
       (s.n_prob_modelo - s.n_cal_ppfacil) AS d_prob_cal_facil,
       (s.n_prob_modelo - s.n_cal_ppcd) AS d_prob_cal_ppcd
FROM opt o
FULL OUTER JOIN nod n ON o.codmes = n.codmes
FULL OUTER JOIN sco s ON COALESCE(o.codmes, n.codmes) = s.codmes
ORDER BY codmes
