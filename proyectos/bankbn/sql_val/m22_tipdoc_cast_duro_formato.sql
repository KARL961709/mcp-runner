-- m22_tipdoc_cast_duro_formato.sql | READ-ONLY | tipo y formato real de tip_doc en RCC madre, RENIEC titular, RENIEC conyuge y VPC: decide si el CAST duro de 2tN_j_mad_bpe.sql:68 aborta la corrida y si el filtro tip_doc <> '2' de :13 y :65 llega a filtrar algo
WITH rcc AS (
    SELECT fuente, max(tipo_col) AS tipo_col, v, count(1) AS filas, sum(es_neg) AS filas_neg
    FROM (
        SELECT 'A_RCC_D_PERM_201506' AS fuente,
               typeof(tip_doc) AS tipo_col,
               cast(tip_doc AS varchar) AS v,
               CASE WHEN try_cast(tipo_credito AS int) BETWEEN 8 AND 10
                     AND ((substr(cast(cod_cuenta_rcc AS varchar),1,2) = '14'
                           AND substr(cast(cod_cuenta_rcc AS varchar),4,1) IN ('1','3','4','5','6')
                           AND substr(cast(cod_cuenta_rcc AS varchar),7,2) NOT IN ('01','04'))
                       OR (substr(cast(cod_cuenta_rcc AS varchar),1,2) = '72'
                           AND substr(cast(cod_cuenta_rcc AS varchar),4,1) = '5'
                           AND substr(cast(cod_cuenta_rcc AS varchar),5,2) IN ('02','03','06','08','09')))
                    THEN 1 ELSE 0 END AS es_neg
        FROM d_perm_aws.t_fact_report_rcc_rsk
        WHERE p_codmes = '201506'
        UNION ALL
        SELECT 'B_RCC_E_PERM_202506',
               typeof(tip_doc),
               cast(tip_doc AS varchar),
               CASE WHEN try_cast(tipo_credito AS int) BETWEEN 8 AND 10
                     AND ((substr(cast(cod_cuenta_rcc AS varchar),1,2) = '14'
                           AND substr(cast(cod_cuenta_rcc AS varchar),4,1) IN ('1','3','4','5','6')
                           AND substr(cast(cod_cuenta_rcc AS varchar),7,2) NOT IN ('01','04'))
                       OR (substr(cast(cod_cuenta_rcc AS varchar),1,2) = '72'
                           AND substr(cast(cod_cuenta_rcc AS varchar),4,1) = '5'
                           AND substr(cast(cod_cuenta_rcc AS varchar),5,2) IN ('02','03','06','08','09')))
                    THEN 1 ELSE 0 END
        FROM e_perm_aws.t_fact_report_rcc_rsk
        WHERE p_codmes = '202506'
    ) z
    GROUP BY fuente, v
),
rnc AS (
    SELECT 'C_RENIEC_TIP_DOC' AS fuente, max(tipo_col) AS tipo_col, v, count(1) AS filas, cast(null AS bigint) AS filas_neg
    FROM (SELECT typeof(tip_doc) AS tipo_col, cast(tip_doc AS varchar) AS v FROM e_perm_aws.t_mst_reniec_rsk) z
    GROUP BY v
),
cny AS (
    SELECT 'D_RENIEC_TIPDOC_CONYUGUE' AS fuente, max(tipo_col) AS tipo_col, v, count(1) AS filas, cast(null AS bigint) AS filas_neg
    FROM (SELECT typeof(tipdoc_conyugue) AS tipo_col, cast(tipdoc_conyugue AS varchar) AS v FROM e_perm_aws.t_mst_reniec_rsk) z
    GROUP BY v
),
vpc AS (
    SELECT 'E_VPC_COD_TIPO_DOC_VAL' AS fuente, max(tipo_col) AS tipo_col, v, count(1) AS filas, cast(null AS bigint) AS filas_neg
    FROM (SELECT typeof(cod_tipo_doc_val) AS tipo_col, cast(cod_tipo_doc_val AS varchar) AS v FROM e_perm_aws.t_mst_vpc_myp_cliente_actual) z
    GROUP BY v
),
todo AS (
    SELECT * FROM rcc
    UNION ALL SELECT * FROM rnc
    UNION ALL SELECT * FROM cny
    UNION ALL SELECT * FROM vpc
),
marca AS (
    SELECT fuente, tipo_col, v, filas, filas_neg,
           CASE WHEN try_cast(v AS int) IS NULL THEN 1 ELSE 0 END AS no_castea,
           count(1) OVER (PARTITION BY fuente) AS n_valores_distintos,
           sum(filas) OVER (PARTITION BY fuente) AS filas_fuente,
           sum(CASE WHEN try_cast(v AS int) IS NULL THEN filas ELSE 0 END) OVER (PARTITION BY fuente) AS filas_que_abortan,
           sum(CASE WHEN try_cast(v AS int) IS NULL THEN coalesce(filas_neg, 0) ELSE 0 END) OVER (PARTITION BY fuente) AS filas_neg_que_abortan,
           row_number() OVER (PARTITION BY fuente ORDER BY CASE WHEN try_cast(v AS int) IS NULL THEN 0 ELSE 1 END, filas DESC) AS rn
    FROM todo
)
SELECT
    fuente,
    tipo_col,
    n_valores_distintos,
    coalesce(v, 'ES_NULL')                                                          AS valor,
    length(coalesce(v, ''))                                                         AS n_chars,
    length(to_utf8(coalesce(v, '')))                                                AS n_bytes,
    CASE WHEN v IS NOT NULL AND v <> trim(v) THEN 1 ELSE 0 END                       AS tiene_espacios,
    CASE WHEN no_castea = 1 THEN 'ABORTA_CAST_L68' ELSE 'CASTEA_OK' END              AS efecto_cast_l68,
    coalesce(cast(try_cast(v AS int) AS varchar), 'NA')                              AS valor_normalizado,
    CASE WHEN no_castea = 1 THEN 'NO_CASTEA'
         WHEN v = cast(try_cast(v AS int) AS varchar) THEN 'SIN_CEROS'
         ELSE 'CON_CEROS' END                                                        AS formato,
    CASE WHEN v = '2' THEN 'FILTRADO_OK'
         WHEN try_cast(v AS int) = 2 THEN 'RUC_ESCAPA_FILTRO_L13_L65'
         ELSE 'NO_ES_RUC' END                                                        AS efecto_filtro_2,
    filas,
    round(100.0 * filas / filas_fuente, 4)                                          AS pct_fuente,
    filas_neg,
    filas_que_abortan,
    filas_neg_que_abortan
FROM marca
WHERE rn <= 6
ORDER BY fuente, rn
