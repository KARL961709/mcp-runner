-- desemb_corr_c2_cruce.sql | VERIFICA que el pd_raw corregido ahora sale del SCR en p_codmes = cod_mes-1 (no cod_mes). Compara probabilidad. cuadra_menos1 debe ser ~n. Agregado.
WITH sc AS (
  SELECT tip_doc, key_value, CAST(p_codmes AS INT) AS pcm, TRY_CAST(probabilidad AS DOUBLE) AS prob
  FROM e_perm_aws.scr_admbankbpe_rsk
  WHERE modelo = 'ADMBANKBPE' AND p_codmes BETWEEN '202602' AND '202608'
),
d AS (
  SELECT cod_tip_doc, key_value, cod_mes, pd_raw
  FROM disc_model_owner.b46029_desemb_cal_corr_202609
  WHERE pd_raw IS NOT NULL AND cod_mes BETWEEN 202603 AND 202608
)
SELECT
  SUM(CASE WHEN a.prob IS NOT NULL AND abs(a.prob - d.pd_raw) < 1e-9 THEN 1 ELSE 0 END) AS cuadra_en_codmes,
  SUM(CASE WHEN b.prob IS NOT NULL AND abs(b.prob - d.pd_raw) < 1e-9 THEN 1 ELSE 0 END) AS cuadra_en_codmes_menos1,
  COUNT(*) AS n
FROM d
LEFT JOIN sc a ON a.tip_doc = d.cod_tip_doc AND a.key_value = d.key_value AND a.pcm = d.cod_mes
LEFT JOIN sc b ON b.tip_doc = d.cod_tip_doc AND b.key_value = d.key_value AND b.pcm = d.cod_mes - 1
