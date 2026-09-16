-- q91 recon ANTES/DESPUES 202607-202608: opt (input) -> nodos -> scored (output). Deltas 0 y nulls 0 en cada etapa. Read-only.
WITH opt AS (
  SELECT codmes, COUNT(*) AS n_opt_dedup, SUM(CASE WHEN prob_model IS NULL THEN 1 ELSE 0 END) AS n_optprob_null FROM (
    SELECT CAST(cod_mes AS varchar) AS codmes, key_value, CAST(cod_tip_doc AS varchar) AS cod_tip_doc, prob_model,
           ROW_NUMBER() OVER (PARTITION BY cod_mes, key_value, cod_tip_doc ORDER BY prob_model DESC) AS rn
    FROM disc_riesgos.scr_vcbankv3_repro_opt_
    WHERE prob_model IS NOT NULL AND CAST(cod_tip_doc AS varchar) = '1'
      AND CAST(cod_mes AS varchar) BETWEEN '202607' AND '202608'
      AND CAST(p_codmes AS varchar) = CAST(cod_mes AS varchar)
  ) WHERE rn = 1 GROUP BY codmes
),
nod AS (
  SELECT CAST(codmes AS varchar) AS codmes, COUNT(*) AS n_nodos, SUM(CASE WHEN pd_raw IS NULL THEN 1 ELSE 0 END) AS n_nodpd_null
  FROM disc_model_owner.scr_admvc_pp_cal_202607_202608_nodos GROUP BY CAST(codmes AS varchar)
),
sco AS (
  SELECT CAST(codmes AS varchar) AS codmes, COUNT(*) AS n_scored,
    SUM(CASE WHEN prob_modelo IS NULL THEN 1 ELSE 0 END) AS n_prob_null,
    SUM(CASE WHEN prob_modelo_cal_ppfacil IS NULL THEN 1 ELSE 0 END) AS n_calfacil_null,
    SUM(CASE WHEN prob_modelo_cal_ppcd IS NULL THEN 1 ELSE 0 END) AS n_calppcd_null
  FROM disc_model_owner.scr_admvc_pp_cal_202607_202608 GROUP BY CAST(codmes AS varchar)
)
SELECT COALESCE(o.codmes, n.codmes, s.codmes) AS codmes,
  o.n_opt_dedup, n.n_nodos, s.n_scored,
  o.n_optprob_null, n.n_nodpd_null, s.n_prob_null, s.n_calfacil_null, s.n_calppcd_null,
  (o.n_opt_dedup - n.n_nodos) AS d_opt_nodos, (n.n_nodos - s.n_scored) AS d_nodos_scored
FROM opt o
FULL OUTER JOIN nod n ON o.codmes = n.codmes
FULL OUTER JOIN sco s ON COALESCE(o.codmes, n.codmes) = s.codmes
ORDER BY codmes
