-- escf_05_srcmax.sql | confirma que el ULTIMO mes de la fuente madre = el que scoreamos. fuente vs entregable. Agregado.
SELECT 'fuente_scr_admbankbpe_rsk' AS que, CAST(MAX(p_codmes) AS VARCHAR) AS max_p_codmes, COUNT(DISTINCT p_codmes) AS n_meses
FROM e_perm_aws.scr_admbankbpe_rsk WHERE modelo='ADMBANKBPE' AND probabilidad IS NOT NULL
UNION ALL
SELECT 'entregable_202501_202609' AS que, CAST(MAX(p_codmes) AS VARCHAR) AS max_p_codmes, COUNT(DISTINCT p_codmes) AS n_meses
FROM disc_model_owner.scr_admbankbpe_rsk_cal_202501_202609
