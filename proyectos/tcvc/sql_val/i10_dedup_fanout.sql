-- i10. H3 fan-out del dedup (pre-dedup en _1_v2): cuantas llaves tienen >1 fila = cuantas veces el desempate por mora FUTURA decide.
SELECT
  COUNT(*) AS n_grains,
  SUM(c) AS n_pre,
  SUM(CASE WHEN c > 1 THEN 1 ELSE 0 END) AS grains_con_dup,
  ROUND(AVG(c), 4) AS avg_filas_por_grain,
  MAX(c) AS max_filas_grain
FROM (
  SELECT codmes_mrm, id_value, tip_doc, cod_instit_financiera, COUNT(*) AS c
  FROM disc_model_owner.enr_admtcbk_1_v2
  WHERE tip_doc = '1'
  GROUP BY codmes_mrm, id_value, tip_doc, cod_instit_financiera
)