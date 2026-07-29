-- c2 | hasta que mes llega cada fuente de driver. Contando filas, no particiones
SELECT 'sit_laboral' AS fuente,
       CAST(periodo AS VARCHAR) AS periodo,
       COUNT(*) AS n_filas,
       COUNT(DISTINCT SUBSTR(subject_id, 3)) AS n_llaves
FROM e_perm_aws.ds_rtd_rskvol_cas_ingr_ir
WHERE CAST(numcarga AS INT) = 1
  AND CAST(periodo AS VARCHAR) >= '202512'
GROUP BY 2
UNION ALL
SELECT 'cta_sueldo',
       CAST(codmes AS VARCHAR),
       COUNT(*),
       COUNT(DISTINCT CAST(key_value AS VARCHAR))
FROM e_perm_aws.t_rsk_cta_sueldo
WHERE CAST(codmes AS VARCHAR) >= '202512'
GROUP BY 2
ORDER BY 1, 2 DESC
