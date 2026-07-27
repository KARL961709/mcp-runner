-- m01_card_lado_izq_tag.sql | READ-ONLY | cardinalidad del set de claves tmp_tag_t1 (filas, grano y claves distintas por mes y acumuladas) que hace de lado izquierdo del INNER JOIN de 1t1_d_rcc: decide broadcast vs join particionado
WITH base AS (
    SELECT
        cast(p_codmes AS varchar)              AS pmes,
        cast(codmes AS varchar)                AS cmes,
        cast(tip_doc AS varchar)               AS td,
        cast(key_value AS varchar)             AS kv,
        cast(cod_instit_financiera AS varchar) AS cif,
        cast(cod_cuenta_rcc AS varchar)        AS cc,
        try_cast(tipo_credito AS int)          AS tc,
        saldo
    FROM d_perm_aws.t_fact_report_rcc_rsk
    WHERE p_codmes BETWEEN '201506' AND '201705'
),
marca AS (
    SELECT pmes, cmes, td, kv, cif, tc, saldo,
        CASE WHEN (substr(cc,1,2)='14' AND substr(cc,4,1) IN ('1','3','4','5','6'))
                  OR (substr(cc,1,2)='72' AND substr(cc,4,1)='5') THEN 1 ELSE 0 END AS en_rama,
        CASE
            WHEN substr(cc,1,2)='14' AND substr(cc,4,1) IN ('1','3','4','5','6') THEN
                CASE WHEN tc BETWEEN 8 AND 10 THEN
                        CASE
                            WHEN tc BETWEEN 8 AND 10 AND substr(cc,7,2)='05' THEN 'DESCUENTOS'
                            WHEN tc BETWEEN 8 AND 10 AND substr(cc,7,2)='10' THEN 'FACTORING'
                            WHEN tc BETWEEN 8 AND 10 AND substr(cc,7,2)='04' THEN 'SOBREGIRO'
                            WHEN tc BETWEEN 8 AND 10 AND substr(cc,7,2)='01' THEN 'AVANCE CC'
                            ELSE 'RESTO DD NEGOCIO'
                        END
                    ELSE 'RESTO DD'
                END
            WHEN substr(cc,1,2)='72' AND substr(cc,4,1)='5' THEN
                CASE WHEN tc BETWEEN 8 AND 10 THEN
                        CASE
                            WHEN tc BETWEEN 8 AND 10 AND substr(cc,5,2)='02' THEN 'LC DESCUENTO'
                            WHEN tc BETWEEN 8 AND 10 AND substr(cc,5,2) IN ('03','06','08','09') THEN 'LC NO UTILIZADA'
                            ELSE 'RESTO LC NEGOCIO'
                        END
                    ELSE 'RESTO LC'
                END
        ELSE 'OTROS' END AS tag,
        CASE WHEN cif IN ('00469','00470','00472','00477','00478','00497','00498','00499','00500','00508',
                    '00509','00510','00512','00513','00514','00516','00517','00518','00519','00580','00581','00582','00583',
                    '00587','00588','00589','00592','00593','00594','00596','00598','00599','00600') THEN 1 ELSE 0 END AS ent_honrada
    FROM base
),
flag AS (
    SELECT pmes, cmes, td, kv, cif, tc, saldo, en_rama,
        CASE WHEN tag IN ('RESTO DD NEGOCIO','DESCUENTOS','FACTORING','LC NO UTILIZADA','LC DESCUENTO')
                  AND ent_honrada = 0
                  AND cmes BETWEEN '201506' AND '201705' THEN 1 ELSE 0 END AS es_tag
    FROM marca
),
mes AS (
    SELECT pmes,
        count(*)                                                                  AS n_filas_rcc,
        sum(CASE WHEN cmes IS NULL OR cmes <> pmes THEN 1 ELSE 0 END)             AS n_cmes_ne_pmes,
        sum(CASE WHEN cmes < '201506' OR cmes > '201705' THEN 1 ELSE 0 END)       AS n_cmes_fuera,
        sum(CASE WHEN en_rama = 1 AND tc IS NULL THEN 1 ELSE 0 END)               AS n_cast_malo,
        sum(es_tag)                                                               AS n_filas_tag,
        sum(CASE WHEN es_tag = 1 AND (td IS NULL OR kv IS NULL) THEN 1 ELSE 0 END) AS n_key_null,
        approx_distinct(CASE WHEN es_tag = 1 THEN td || '|' || kv || '|' || cif END)                 AS n_grano_tag,
        approx_distinct(CASE WHEN es_tag = 1 AND saldo > 0 THEN td || '|' || kv || '|' || cif END)   AS n_grano_pos,
        approx_set(CASE WHEN es_tag = 1 THEN td || '|' || kv END)                 AS hll_key,
        avg(CASE WHEN es_tag = 1 THEN cast(length(td) + length(kv) AS double) END) AS bytes_key
    FROM flag
    GROUP BY pmes
),
acum AS (
    SELECT pmes, n_filas_rcc, n_filas_tag, n_grano_tag, n_grano_pos,
        n_cmes_ne_pmes, n_cmes_fuera, n_key_null, n_cast_malo, bytes_key,
        cardinality(hll_key) AS n_keys_mes,
        cardinality(merge(hll_key) OVER (ORDER BY pmes ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)) AS n_keys_acum
    FROM mes
)
SELECT
    pmes                                                             AS mes,
    n_filas_rcc,
    n_filas_tag,
    n_grano_tag,
    n_grano_pos,
    n_keys_mes,
    n_keys_acum,
    n_keys_acum - lag(n_keys_acum) OVER (ORDER BY pmes)              AS n_keys_nuevas,
    round(bytes_key, 1)                                              AS bytes_key,
    round(n_keys_acum * (bytes_key + 32) / 1048576.0, 1)             AS mb_set_est,
    n_cmes_ne_pmes,
    n_cmes_fuera,
    n_key_null,
    n_cast_malo
FROM acum
ORDER BY 1
