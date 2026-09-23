-- cmp_escopt_v21.sql | compara nuestra base prob_modelo_cal vs las 2 versiones enviadas (_v2 vieja? y _v21 nueva?) en 202607/202608. La que de mae~0 es la que reproducimos. Agregado.
SELECT o.p_codmes, COUNT(*) AS n,
  ROUND(100*AVG(o.prob_modelo_cal),4) AS pd_new,
  ROUND(100*AVG(s.prob_modelo_cal_v2),4) AS pd_v2,
  ROUND(1000*AVG(ABS(o.prob_modelo_cal - s.prob_modelo_cal_v2)),4) AS mae_v2_x10,
  ROUND(100*AVG(s.prob_modelo_cal_v21),4) AS pd_v21,
  ROUND(1000*AVG(ABS(o.prob_modelo_cal - s.prob_modelo_cal_v21)),4) AS mae_v21_x10
FROM disc_model_owner.scr_admbankbpe_calibrado_202609_escopt o
JOIN d_perm_aws.scr_admbankbpe_rsk_cal_202501_202608 s ON s.tip_doc=o.tip_doc AND s.key_value=o.key_value AND s.p_codmes=CAST(o.p_codmes AS INT)
WHERE o.p_codmes IN ('202607','202608')
GROUP BY o.p_codmes ORDER BY o.p_codmes
