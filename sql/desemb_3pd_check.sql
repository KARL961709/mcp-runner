-- desemb_3pd_check.sql | agregado de las 3 PDs (read-only, _resultados.txt). Correr junto: .\Go.ps1 -Only desemb_3pd,desemb_3pd_check
SELECT CASE WHEN cod_tip_doc='2' THEN 'PJ' ELSE 'PN' END AS personeria,
       COUNT(*) AS n, ROUND(100.0*AVG(flg_match_v2),1) AS pct_v2,
       ROUND(100*AVG(pd_raw),2) AS pd_raw_pct,
       ROUND(100*AVG(pd_cal_pit),2) AS pd_cal_pit_pct,
       ROUND(100*AVG(CASE WHEN flg_match_v2=1 THEN pd_opt_v2 END),2) AS pd_opt_v2_pct
FROM disc_model_owner.b46029_desemb_3pd_202609 GROUP BY 1 ORDER BY 1
