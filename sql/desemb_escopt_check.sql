-- desemb_escopt_check.sql | VALIDA el cruce escopt<->desembolso (read-only, sale a _resultados.txt):
--   1) cobertura del match por personeria, 2) que pd_raw del desembolso == prob_raw del scr (MAD ~0 => join correcto),
--   3) PD escenario optimo vs RD12 realizada (maduras) por personeria -> para ver el sesgo del factor de altas en desembolsos.
--   Correr junto con el CTAS:  .\Go.ps1 -Only desemb_escopt,desemb_escopt_check -Bajar
WITH s AS (
  SELECT CAST(p_codmes AS INTEGER) AS p_codmes,
         tip_doc, key_value,
         TRY_CAST(probabilidad AS DOUBLE) AS prob_raw_scr,
         prob_modelo_cal,
         ROW_NUMBER() OVER (PARTITION BY p_codmes, tip_doc, key_value ORDER BY fec_replica DESC) AS rn
  FROM disc_model_owner.scr_admbankbpe_calibrado_202607
),
j AS (
  SELECT d.cod_mes, d.cod_tip_doc, d.pd_raw, d.meses_madurez, d.target_12m,
         s.prob_raw_scr, s.prob_modelo_cal,
         GREATEST(1e-6, LEAST(1 - 1e-6,
           s.prob_modelo_cal * CASE WHEN d.cod_tip_doc = '2' THEN 0.68140 ELSE 0.96970 END)) AS pd_esc_opt,
         CASE WHEN s.prob_modelo_cal IS NULL THEN 0 ELSE 1 END AS flg_match
  FROM disc_model_owner.b46029_desemb_cal_202609 d
  LEFT JOIN s
    ON s.tip_doc = d.cod_tip_doc AND s.key_value = d.key_value AND s.p_codmes = d.cod_mes AND s.rn = 1
)
SELECT
  CASE WHEN cod_tip_doc = '2' THEN 'PJ (PJJ)' ELSE 'PN (PNN)' END       AS personeria,
  COUNT(*)                                                              AS n_desemb,
  SUM(flg_match)                                                        AS n_match,
  ROUND(100.0 * SUM(flg_match) / COUNT(*), 1)                           AS pct_match,
  ROUND(AVG(CASE WHEN flg_match = 1 THEN ABS(pd_raw - prob_raw_scr) END), 5) AS mad_pdraw_vs_scr,
  ROUND(100 * AVG(CASE WHEN meses_madurez = 12 AND flg_match = 1 THEN pd_esc_opt END), 2) AS pd_escopt_mad_pct,
  ROUND(100 * AVG(CASE WHEN meses_madurez = 12 THEN target_12m END), 2) AS rd12_mad_pct
FROM j
GROUP BY 1
ORDER BY 1
