-- m20_replegal_join_sin_tipdoc.sql | READ-ONLY | sobre el universo de claves con credito negocio del RCC, cuantas claves NO-RUC (tip_doc<>'2') enganchan un ruc_value de SUNAT RRLL: decide si 2tN_d_mad_rl.sql:15 necesita el filtro b.tip_doc='2'
WITH base AS (
    SELECT
        cast(p_codmes AS varchar)       AS pmes,
        cast(codmes AS varchar)         AS cmes,
        cast(tip_doc AS varchar)        AS td,
        cast(key_value AS varchar)      AS kv,
        cast(cod_cuenta_rcc AS varchar) AS cc,
        try_cast(tipo_credito AS int)   AS tc
    FROM d_perm_aws.t_fact_report_rcc_rsk
    WHERE p_codmes = '201506'
    UNION ALL
    SELECT
        cast(p_codmes AS varchar),
        cast(codmes AS varchar),
        cast(tip_doc AS varchar),
        cast(key_value AS varchar),
        cast(cod_cuenta_rcc AS varchar),
        try_cast(tipo_credito AS int)
    FROM e_perm_aws.t_fact_report_rcc_rsk
    WHERE p_codmes = '202506'
),
tag AS (
    SELECT pmes, cmes, td, kv
    FROM base
    WHERE tc BETWEEN 8 AND 10
      AND ((substr(cc,1,2)='14' AND substr(cc,4,1) IN ('1','3','4','5','6') AND substr(cc,7,2) NOT IN ('01','04'))
        OR (substr(cc,1,2)='72' AND substr(cc,4,1)='5' AND substr(cc,5,2) IN ('02','03','06','08','09')))
),
llaves AS (
    SELECT pmes, td, kv, min(cmes) AS cmes_min, max(cmes) AS cmes_max
    FROM tag
    GROUP BY 1, 2, 3
),
rl AS (
    SELECT cast(ruc_value AS varchar) AS ruc, count(*) AS n_rl
    FROM e_perm_aws.t_mst_rep_legal_sunat_rsk
    GROUP BY 1
)
SELECT
    a.pmes                                             AS mes,
    a.td                                               AS tip_doc,
    count(*)                                           AS n_llaves,
    min(a.cmes_min)                                    AS cmes_min,
    max(a.cmes_max)                                    AS cmes_max,
    min(length(a.kv))                                  AS len_min,
    max(length(a.kv))                                  AS len_max,
    sum(CASE WHEN length(a.kv) = 11 THEN 1 ELSE 0 END) AS n_len11,
    count(b.ruc)                                       AS n_pega_rrll,
    round(100.0 * count(b.ruc) / count(*), 4)          AS pct_pega_rrll,
    coalesce(sum(b.n_rl), 0)                           AS n_filas_rl,
    coalesce(max(b.n_rl), 0)                           AS max_rl_llave
FROM llaves a
LEFT JOIN rl b
    ON a.kv = b.ruc
GROUP BY 1, 2
ORDER BY 1, 2
