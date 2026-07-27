-- m21_clasif_deudor_dominio.sql | READ-ONLY | tipo real y dominio de cod_clasificacion_deudor en d_perm y e_perm, en los 4 extremos de particion que lee el build: decide si las comparaciones contra el literal 0 de 2tN_h_mad_rccbwd:37, 2tN_l_mad:192 y 4b_cal:69 compilan y si dejan poblacion normal
WITH base AS (
    SELECT 'D1_DPERM_201406'                          AS fuente,
           typeof(cod_clasificacion_deudor)           AS tipo_col,
           cast(cod_clasificacion_deudor AS varchar)  AS v,
           cast(cod_cuenta_rcc AS varchar)            AS cc,
           try_cast(tipo_credito AS integer)          AS tc
    FROM d_perm_aws.t_fact_report_rcc_rsk
    WHERE p_codmes = '201406'
    UNION ALL
    SELECT 'D2_DPERM_202105',
           typeof(cod_clasificacion_deudor),
           cast(cod_clasificacion_deudor AS varchar),
           cast(cod_cuenta_rcc AS varchar),
           try_cast(tipo_credito AS integer)
    FROM d_perm_aws.t_fact_report_rcc_rsk
    WHERE p_codmes = '202105'
    UNION ALL
    SELECT 'E1_EPERM_201906',
           typeof(cod_clasificacion_deudor),
           cast(cod_clasificacion_deudor AS varchar),
           cast(cod_cuenta_rcc AS varchar),
           try_cast(tipo_credito AS integer)
    FROM e_perm_aws.t_fact_report_rcc_rsk
    WHERE p_codmes = '201906'
    UNION ALL
    SELECT 'E2_EPERM_202606',
           typeof(cod_clasificacion_deudor),
           cast(cod_clasificacion_deudor AS varchar),
           cast(cod_cuenta_rcc AS varchar),
           try_cast(tipo_credito AS integer)
    FROM e_perm_aws.t_fact_report_rcc_rsk
    WHERE p_codmes = '202606'
),
agg AS (
    SELECT
        fuente,
        v,
        max(tipo_col) AS tipo_col,
        count(1)      AS filas,
        sum(CASE WHEN substr(cc,1,2) = '14' AND substr(cc,4,1) IN ('1','3','4','5','6')
                  AND substr(cc,7,2) NOT IN ('01','04') THEN 1 ELSE 0 END) AS filas_peri_bwd,
        sum(CASE WHEN substr(cc,1,2) = '14' AND substr(cc,4,1) IN ('1','3','4','5','6')
                  AND substr(cc,7,2) NOT IN ('01','04') AND tc BETWEEN 1 AND 10 THEN 1 ELSE 0 END) AS filas_peri_clasif
    FROM base
    GROUP BY fuente, v
)
SELECT
    fuente,
    tipo_col,
    CASE WHEN tipo_col LIKE 'varchar%' THEN 'OK_TEXTO'
         WHEN tipo_col LIKE 'char%'    THEN 'CHAR_PAD_REVISAR'
         ELSE 'NO_TEXTO_ABORTA' END                                          AS veredicto_tipo,
    coalesce(v, 'ES_NULL')                                                   AS valor,
    length(coalesce(v, ''))                                                  AS n_chars,
    length(to_utf8(coalesce(v, '')))                                         AS n_bytes,
    CASE WHEN v IS NOT NULL AND v <> trim(v) THEN 'CON_ESPACIOS'
         ELSE 'SIN_ESPACIOS' END                                             AS espacios,
    CASE WHEN v IS NULL THEN 'NULL_PASA_COMO_NORMAL'
         WHEN v = '0'   THEN 'NORMAL_MATCHEA_LITERAL'
         ELSE 'NO_NORMAL' END                                                AS trato_build,
    filas,
    round(100.0 * filas / sum(filas) OVER (PARTITION BY fuente), 3)          AS pct_filas,
    filas_peri_clasif,
    round(100.0 * filas_peri_clasif
          / nullif(sum(filas_peri_clasif) OVER (PARTITION BY fuente), 0), 3) AS pct_peri_clasif,
    filas_peri_bwd,
    round(100.0 * filas_peri_bwd
          / nullif(sum(filas_peri_bwd) OVER (PARTITION BY fuente), 0), 3)    AS pct_peri_bwd
FROM agg
ORDER BY fuente, filas DESC
LIMIT 40
