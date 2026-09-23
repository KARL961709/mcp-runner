-- cmp_v21.sql | es prob_modelo_cal_v21 (enviada) = el 6a bloque-unico? compara mi calibrado_202609.prob_modelo_cal vs enviada.prob_modelo_cal_v21 en 202607/608. mae~0 = si. + relacion codmes/p_codmes de la enviada. Agregado.
SELECT c.p_codmes,
  COUNT(*) AS n,
  ROUND(100*AVG(c.prob_modelo_cal),4) AS pd_6a,
  ROUND(100*AVG(s.prob_modelo_cal_v21),4) AS pd_v21_env,
  ROUND(1000*AVG(ABS(c.prob_modelo_cal - s.prob_modelo_cal_v21)),4) AS mae_v21_x10,
  MIN(s.codmes) AS codmes_min, MAX(s.codmes) AS codmes_max
FROM disc_model_owner.scr_admbankbpe_calibrado_202609 c
JOIN d_perm_aws.scr_admbankbpe_rsk_cal_202501_202608 s ON s.tip_doc=c.tip_doc AND s.key_value=c.key_value AND s.p_codmes=CAST(c.p_codmes AS INT)
WHERE CAST(c.p_codmes AS INT) IN (202607,202608)
GROUP BY c.p_codmes ORDER BY c.p_codmes
