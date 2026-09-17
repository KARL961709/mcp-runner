-- desemb_3pd_check.sql | backtest de las 3 PDs vs RD12 realizada, sobre MADURAS (read-only, _resultados.txt).
--   Correr junto: .\Go.ps1 -Only desemb_3pd,desemb_3pd_check
SELECT CASE WHEN cod_tip_doc='2' THEN 'PJ' ELSE 'PN' END AS personeria,
       COUNT(*) AS n, COUNT(CASE WHEN meses_madurez=12 THEN 1 END) AS n_mad,
       ROUND(100.0*AVG(flg_match_v2),1) AS pct_v2,
       ROUND(100*AVG(CASE WHEN meses_madurez=12 THEN pd_raw END),2) AS pd_raw,
       ROUND(100*AVG(CASE WHEN meses_madurez=12 THEN pd_cal_pit END),2) AS pd_cal_pit,
       ROUND(100*AVG(CASE WHEN meses_madurez=12 AND flg_match_v2=1 THEN pd_opt_v2 END),2) AS pd_opt_v2,
       ROUND(100*AVG(CASE WHEN meses_madurez=12 THEN target_12m END),2) AS rd12_real
FROM disc_model_owner.b46029_desemb_3pd_202609 GROUP BY 1
UNION ALL
SELECT 'TOTAL', COUNT(*), COUNT(CASE WHEN meses_madurez=12 THEN 1 END), ROUND(100.0*AVG(flg_match_v2),1),
       ROUND(100*AVG(CASE WHEN meses_madurez=12 THEN pd_raw END),2),
       ROUND(100*AVG(CASE WHEN meses_madurez=12 THEN pd_cal_pit END),2),
       ROUND(100*AVG(CASE WHEN meses_madurez=12 AND flg_match_v2=1 THEN pd_opt_v2 END),2),
       ROUND(100*AVG(CASE WHEN meses_madurez=12 THEN target_12m END),2)
FROM disc_model_owner.b46029_desemb_3pd_202609 ORDER BY 1
