-- QA[5] CROSS-CHECK vs la maestra de desembolsos: para los desembolsos scoreados, prob_modelo_cal debe ~ pd_pit_final (donde el desc_cliente derivado = real). Cuadre del metodo entero.
SELECT CASE WHEN m.desc_cliente=c.desc_cliente_cal THEN 'desc_ok' ELSE 'desc_dif' END AS match_desc,
  COUNT(*) AS n,
  ROUND(100*AVG(m.pd_pit_final),3) AS pd_maestra, ROUND(100*AVG(c.prob_modelo_cal),3) AS pd_scr_cal,
  ROUND(1000*AVG(ABS(m.pd_pit_final-c.prob_modelo_cal)),4) AS mae_x10
FROM disc_model_owner.b46029_desemb_maestra_202609 m
JOIN disc_model_owner.b46029_scr_admbankbpe_cal_202608 c ON c.tip_doc=m.cod_tip_doc AND c.key_value=m.key_value AND CAST(c.p_codmes AS INT)=m.cod_mes
WHERE m.flg_cruce=1
GROUP BY CASE WHEN m.desc_cliente=c.desc_cliente_cal THEN 'desc_ok' ELSE 'desc_dif' END ORDER BY 1
