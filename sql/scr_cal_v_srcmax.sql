-- scr_cal_v_srcmax.sql | TECHO de la fuente: meses disponibles y conteo en e_perm_aws.scr_admbankbpe_rsk (modelo ADMBANKBPE). Muestra la cola desde 202605 con n filas y n con probabilidad (pd_raw) para fijar hasta que p_codmes hay dato ANTES de fijar el rango del rebuild. Read-only, agregado.
SELECT p_codmes,
  COUNT(*) AS n,
  SUM(CASE WHEN probabilidad IS NOT NULL THEN 1 ELSE 0 END) AS n_pd,
  ROUND(100.0*AVG(TRY_CAST(probabilidad AS DOUBLE)),3) AS pd_raw_prom_pct
FROM e_perm_aws.scr_admbankbpe_rsk
WHERE modelo = 'ADMBANKBPE' AND p_codmes >= '202605'
GROUP BY p_codmes ORDER BY p_codmes
