-- scr_escopt_c_qa.sql | QA cobertura por p_codmes x flg_match (1=bankbn 2=rebuilt), avg pd, nulls, dist grupos. Agregado.
SELECT p_codmes, flg_match_v2, COUNT(*) AS n,
  ROUND(100*AVG(pd_v2_esc_opt),3) AS pd_avg_pct,
  SUM(CASE WHEN pd_v2_esc_opt IS NULL THEN 1 ELSE 0 END) AS pd_null,
  SUM(CASE WHEN grupos_ant='Bajo' THEN 1 ELSE 0 END) AS g_bajo,
  SUM(CASE WHEN grupos_ant='Alto' THEN 1 ELSE 0 END) AS g_alto
FROM disc_model_owner.b46029_escopt_3m_202608
GROUP BY p_codmes, flg_match_v2 ORDER BY p_codmes, flg_match_v2
