-- x5  hasta que mes llega el PERIMETRO, no el score
-- El score alcanza 202607, pero la poblacion la define la marca de reenganche.
-- Si la marca muere antes, extender el score no agrega cohortes puntuables.
SELECT 'marca_reenganche' AS fuente,
       CAST(MIN(codmes_desembolso) AS VARCHAR) AS mes_min,
       CAST(MAX(codmes_desembolso) AS VARCHAR) AS mes_max,
       CAST(COUNT(DISTINCT codmes_desembolso) AS VARCHAR) AS n_meses,
       CAST(COUNT(*) AS VARCHAR) AS n_filas
FROM d_perm_aws.t_mrm_mongest_altas_pp_marcas_maa_tmp
WHERE subproducto = '1.REENGANCHE'
UNION ALL
SELECT 'marca_ultimos_meses',
       CAST(codmes_desembolso AS VARCHAR), '', '',
       CAST(COUNT(*) AS VARCHAR)
FROM d_perm_aws.t_mrm_mongest_altas_pp_marcas_maa_tmp
WHERE subproducto = '1.REENGANCHE' AND CAST(codmes_desembolso AS VARCHAR) >= '202601'
GROUP BY CAST(codmes_desembolso AS VARCHAR)
ORDER BY 1, 2
