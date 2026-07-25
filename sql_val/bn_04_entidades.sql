-- ============================================================================
-- BN 04. CODIGOS ENTIDAD (Top-4: BCP / BBVA / Scotia / IBK)
-- ============================================================================
SELECT cod_instit_financiera, nombre_instit_financiera
FROM e_perm_aws.t_dim_inst_fin_rsk
WHERE upper(nombre_instit_financiera) LIKE '%CREDITO DEL PERU%'
   OR upper(nombre_instit_financiera) LIKE '%BBVA%'
   OR upper(nombre_instit_financiera) LIKE '%SCOTIA%'
   OR upper(nombre_instit_financiera) LIKE '%INTERBANK%'
ORDER BY nombre_instit_financiera
;
