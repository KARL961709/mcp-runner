-- e1d COBERTURA SUNAT PRINCIPAL (fecalta -> PIT vs snapshot)
SELECT 'sunat_princ' AS fuente, COUNT(*) AS filas, COUNT(DISTINCT ruc_value) AS rucs,
       MIN(CAST(fecalta AS VARCHAR)) AS min_fecalta, MAX(CAST(fecalta AS VARCHAR)) AS max_fecalta
FROM e_perm_aws.t_mst_princ_sunat_rsk
