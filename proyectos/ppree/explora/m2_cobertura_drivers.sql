-- m2  hasta que mes llegan las fuentes de los drivers, contando filas
-- tipo_ingreso_dep sale de la situacion laboral; flg_cs de la cuenta sueldo.
-- Si alguna muere antes que la poblacion, el driver queda nulo en las cohortes nuevas.
SELECT 'situacion_laboral' AS fuente,
       CAST(periodo AS VARCHAR) AS mes,
       COUNT(*)                 AS n_filas,
       COUNT(DISTINCT key_value) AS n_llaves
FROM e_perm_aws.ds_rtd_rskvol_cas_ingr_ir
WHERE CAST(periodo AS VARCHAR) >= '202512'
GROUP BY CAST(periodo AS VARCHAR)
UNION ALL
SELECT 'cuenta_sueldo',
       CAST(codmes AS VARCHAR),
       COUNT(*),
       COUNT(DISTINCT key_value)
FROM e_perm_aws.t_rsk_cta_sueldo
WHERE CAST(codmes AS VARCHAR) >= '202512'
GROUP BY CAST(codmes AS VARCHAR)
ORDER BY 1, 2
