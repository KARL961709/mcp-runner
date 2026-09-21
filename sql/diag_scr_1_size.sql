-- diag_scr_1_size | tamano del universo a scorear: scr_admbankbpe_rsk (ADMBANKBPE) desde p_codmes 202501, por campana. Agregado.
SELECT CAST(p_codmes AS INTEGER) AS p_codmes, COUNT(*) AS n_filas, COUNT(DISTINCT key_value) AS n_keys FROM e_perm_aws.scr_admbankbpe_rsk WHERE modelo = 'ADMBANKBPE' AND probabilidad IS NOT NULL AND p_codmes >= '202501' GROUP BY CAST(p_codmes AS INTEGER) ORDER BY 1
