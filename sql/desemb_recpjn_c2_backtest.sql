-- desemb_recpjn_c2_backtest.sql | backtest por sub-segmento (ventana 202501-207 maduras): pd_pit vs pd_pit_final (con PJ_NUEVO 0.85) vs RD12. Agregado.
SELECT seg,
  COUNT(CASE WHEN meses_madurez=12 THEN 1 END) AS n_mad,
  ROUND(100*AVG(pd_pit),2) AS pd_pit,
  ROUND(100*AVG(pd_pit_final),2) AS pd_pit_final,
  ROUND(100*AVG(CASE WHEN meses_madurez=12 THEN target_12m END),2) AS rd12
FROM disc_model_owner.b46029_desemb_maestra_recpjn_202609
WHERE flg_cruce=1 AND cod_mes BETWEEN 202501 AND 202507
GROUP BY seg ORDER BY seg
