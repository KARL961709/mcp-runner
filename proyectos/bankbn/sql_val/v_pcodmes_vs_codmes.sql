-- verifica si p_codmes == codmes siempre (si si, el margen +-2m sobra)
SELECT 'e_perm' AS fuente, COUNT(*) AS filas,
       SUM(CASE WHEN p_codmes <> codmes THEN 1 ELSE 0 END) AS distintos,
       COUNT(DISTINCT CASE WHEN p_codmes <> codmes THEN p_codmes END) AS particiones_con_dif
FROM e_perm_aws.t_fact_report_rcc_rsk
WHERE p_codmes BETWEEN '202401' AND '202406'
