-- c4 | formato de las llaves en LOS DOS lados de cada join, antes de cruzar.
--      Un largo o un padding distinto no falla: devuelve cero match en silencio
SELECT 'score.key_value'  AS campo, CAST(length(CAST(key_value AS VARCHAR)) AS VARCHAR) AS valor, COUNT(*) AS n
FROM disc_riesgos.t_b39918_scr_stockpp_itc_reprocesov4
WHERE CAST(codmes AS VARCHAR) = '202607'
GROUP BY 2
UNION ALL
SELECT 'score.cod_tip_doc', CAST(cod_tip_doc AS VARCHAR), COUNT(*)
FROM disc_riesgos.t_b39918_scr_stockpp_itc_reprocesov4
WHERE CAST(codmes AS VARCHAR) = '202607'
GROUP BY 2
UNION ALL
SELECT 'sit_lab.id_value', CAST(length(SUBSTR(subject_id, 3)) AS VARCHAR), COUNT(*)
FROM e_perm_aws.ds_rtd_rskvol_cas_ingr_ir
WHERE CAST(numcarga AS INT) = 1 AND CAST(periodo AS VARCHAR) = '202606'
GROUP BY 2
UNION ALL
SELECT 'sit_lab.tip_doc', CAST(tip_doc AS VARCHAR), COUNT(*)
FROM e_perm_aws.ds_rtd_rskvol_cas_ingr_ir
WHERE CAST(numcarga AS INT) = 1 AND CAST(periodo AS VARCHAR) = '202606'
GROUP BY 2
UNION ALL
SELECT 'cta_sueldo.id_value', CAST(length(CAST(key_value AS VARCHAR)) AS VARCHAR), COUNT(*)
FROM e_perm_aws.t_rsk_cta_sueldo
WHERE CAST(codmes AS VARCHAR) = '202605'
GROUP BY 2
UNION ALL
SELECT 'cta_sueldo.tip_doc', CAST(CAST(tipdoc AS INTEGER) AS VARCHAR), COUNT(*)
FROM e_perm_aws.t_rsk_cta_sueldo
WHERE CAST(codmes AS VARCHAR) = '202605'
GROUP BY 2
ORDER BY 1, 3 DESC
