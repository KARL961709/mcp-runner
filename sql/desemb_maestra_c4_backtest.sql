-- QA[4] BACKTEST: PD vs RD12 (maduras, universo calibracion <=2025Q1) por personeria, calce pd_pit_final
SELECT CASE WHEN cod_tip_doc='2' THEN 'PJ' ELSE 'PN' END AS personeria,
  COUNT(CASE WHEN meses_madurez=12 THEN 1 END) AS n_mad,
  ROUND(100*AVG(CASE WHEN meses_madurez=12 THEN pd_pit END),2) AS pd_pit,
  ROUND(100*AVG(CASE WHEN meses_madurez=12 THEN pd_pit_final END),2) AS pd_pit_final,
  ROUND(100*AVG(CASE WHEN meses_madurez=12 THEN pd_v2_esc_opt END),2) AS pd_v2_escopt,
  ROUND(100*AVG(CASE WHEN meses_madurez=12 THEN target_12m END),2) AS rd12
FROM disc_model_owner.b46029_desemb_maestra_202609
WHERE flg_cruce=1 AND flg_universo_calib=1 AND cod_mes<=202503
GROUP BY 1 ORDER BY 1
