-- e1e COBERTURA SUNAT REP LEGAL (fec_vigencia)
SELECT 'sunat_replegal' AS fuente, COUNT(*) AS filas,
       MIN(CAST(fec_vigencia AS VARCHAR)) AS min_vig, MAX(CAST(fec_vigencia AS VARCHAR)) AS max_vig
FROM e_perm_aws.t_mst_rep_legal_sunat_rsk
