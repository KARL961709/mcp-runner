-- 08_altas_fuente.sql | volumen de altas TC por fuente y mes, para confirmar si el universo del modelo vigente es solo IBK o todo el sistema financiero
SELECT p_codmes,
       sum(CASE WHEN fuente = 'SSFF' THEN 1 ELSE 0 END)                                      AS n_ssff,
       sum(CASE WHEN fuente = 'IBK' THEN 1 ELSE 0 END)                                       AS n_ibk,
       sum(CASE WHEN fuente = 'SSFF' AND codempresa = '00002' THEN 1 ELSE 0 END)             AS n_ssff_cod00002,
       count(*)                                                                              AS n_total
FROM (
    SELECT 'SSFF' AS fuente, p_codmes, ltrim(rtrim(codempresa)) AS codempresa
    FROM e_perm_aws.tng_altas_ssff_rsk
    WHERE p_codmes >= '202401'
    UNION ALL
    SELECT 'IBK' AS fuente, p_codmes, '00002' AS codempresa
    FROM e_perm_aws.tng_altas_ibk_rsk
    WHERE p_codmes >= '202401'
) a
GROUP BY p_codmes
ORDER BY p_codmes
