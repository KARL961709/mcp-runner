-- qa_30_grano_drivers.sql | INV-D02 grano unico (codmes,tip_doc,key_value) en drivers | aprueba si n_filas = n_granos en cada fila y n_granos_dup = 0 en TOTAL
WITH g AS (
    SELECT
        SUBSTRING(CAST(codmes AS VARCHAR),1,4) AS anio,
        codmes,
        tip_doc,
        key_value,
        COUNT(*) AS n_filas_grano,
        COUNT(DISTINCT cod_instit_financiera) AS n_ent_grano
    FROM disc_model_owner.ds_adm_bpe_bankbn_drivers
    GROUP BY 1,2,3,4
),
det AS (
    SELECT
        anio,
        COUNT(*) AS n_granos,
        SUM(n_filas_grano) AS n_filas,
        SUM(n_filas_grano) - COUNT(*) AS n_filas_extra,
        SUM(CASE WHEN n_filas_grano > 1 THEN 1 ELSE 0 END) AS n_granos_dup,
        SUM(CASE WHEN n_ent_grano > 1 THEN 1 ELSE 0 END) AS n_granos_multi_ent,
        MAX(n_filas_grano) AS max_filas_x_grano
    FROM g
    GROUP BY 1
)
SELECT
    anio,
    n_granos,
    n_filas,
    n_filas_extra,
    n_granos_dup,
    n_granos_multi_ent,
    max_filas_x_grano,
    CASE WHEN n_granos_dup = 0 THEN 'OK' ELSE 'FALLA' END AS veredicto
FROM det
UNION ALL
SELECT
    'TOTAL',
    SUM(n_granos),
    SUM(n_filas),
    SUM(n_filas_extra),
    SUM(n_granos_dup),
    SUM(n_granos_multi_ent),
    MAX(max_filas_x_grano),
    CASE WHEN SUM(n_granos_dup) = 0 THEN 'OK' ELSE 'FALLA' END
FROM det
ORDER BY 1
