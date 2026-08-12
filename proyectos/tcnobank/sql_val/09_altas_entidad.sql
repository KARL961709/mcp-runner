-- 09_altas_entidad.sql | reparto de altas TC por entidad emisora, para dimensionar cuanto universo elimina el filtro de 5 entidades del modelo vigente
SELECT a.codempresa,
       e.nombre_instit_financiera,
       count(*)                                                     AS n_altas,
       count(DISTINCT a.p_codmes)                                   AS meses,
       round(100.0 * count(*) / sum(count(*)) OVER (), 3)           AS pct
FROM (
    SELECT ltrim(rtrim(codempresa)) AS codempresa, p_codmes
    FROM e_perm_aws.tng_altas_ssff_rsk
    WHERE p_codmes >= '202401'
    UNION ALL
    SELECT '00002' AS codempresa, p_codmes
    FROM e_perm_aws.tng_altas_ibk_rsk
    WHERE p_codmes >= '202401'
) a
LEFT JOIN e_perm_aws.t_dim_inst_fin_rsk e
       ON ltrim(rtrim(e.cod_instit_financiera)) = a.codempresa
GROUP BY a.codempresa, e.nombre_instit_financiera
ORDER BY n_altas DESC
LIMIT 45
