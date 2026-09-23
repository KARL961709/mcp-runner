-- cmp_ratios.sql | mide DIRECTO en la enviada el factor de _v2_opt y _v21 respecto de _v2, por personeria (202607). Si sd~0 => es factor constante (reproducible). Si sd grande => _v21 es otra calibracion. Agregado.
SELECT personeria,
  COUNT(*) AS n,
  ROUND(AVG(prob_modelo_cal_v2_opt/prob_modelo_cal_v2),5) AS r_opt,
  ROUND(STDDEV(prob_modelo_cal_v2_opt/prob_modelo_cal_v2),5) AS sd_opt,
  ROUND(AVG(prob_modelo_cal_v21/prob_modelo_cal_v2),5) AS r_v21,
  ROUND(STDDEV(prob_modelo_cal_v21/prob_modelo_cal_v2),5) AS sd_v21
FROM d_perm_aws.scr_admbankbpe_rsk_cal_202501_202608
WHERE p_codmes=202607 AND prob_modelo_cal_v2 > 0
GROUP BY personeria ORDER BY personeria
