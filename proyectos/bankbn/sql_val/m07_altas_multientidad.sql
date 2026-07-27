-- m07_altas_multientidad.sql | READ-ONLY | mide altas simultaneas del mismo cliente en dos entidades el mismo mes y cuantas altas IBK 00002 borra el rn=1 ORDER BY cod_instit_financiera ASC de 1tN_h_po.sql:74-78 a favor de BCP 00001
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
    FROM e_perm_aws.t_fact_report_rcc_rsk
    WHERE p_codmes BETWEEN '202301' AND '202312'
),
tagged AS (
    SELECT pmes, cmes, td, kv, cif, saldo,
        CASE
            WHEN substr(cc,1,2)='14' AND substr(cc,4,1) IN ('1','3','4','5','6') THEN
                CASE WHEN tc BETWEEN 8 AND 10 THEN
                        CASE
                            WHEN substr(cc,7,2)='05' THEN 'DESCUENTOS'
                            WHEN substr(cc,7,2)='10' THEN 'FACTORING'
                            WHEN substr(cc,7,2)='04' THEN 'SOBREGIRO'
                            WHEN substr(cc,7,2)='01' THEN 'AVANCE CC'
                            ELSE 'RESTO DD NEGOCIO'
                        END
                    ELSE 'RESTO DD'
                END
            WHEN substr(cc,1,2)='72' AND substr(cc,4,1)='5' THEN
                CASE WHEN tc BETWEEN 8 AND 10 THEN
                        CASE
                            WHEN substr(cc,5,2)='02' THEN 'LC DESCUENTO'
                            WHEN substr(cc,5,2) IN ('03','06','08','09') THEN 'LC NO UTILIZADA'
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
ent_mes AS (
    SELECT cmes, td, kv, cif,
        try_cast(substr(cmes,1,4) AS int) * 12 + try_cast(substr(cmes,5,2) AS int) AS midx,
        sum(saldo)                                                    AS s_neg,
        count(*)                                                      AS n_row,
        sum(CASE WHEN pmes IS NULL OR pmes <> cmes THEN 1 ELSE 0 END) AS n_desf
    FROM tagged
    WHERE tag IN ('RESTO DD NEGOCIO','DESCUENTOS','FACTORING','LC NO UTILIZADA','LC DESCUENTO')
      AND ent_honrada = 0
    GROUP BY 1,2,3,4,5
),
pos AS (
    SELECT cmes, midx, td, kv, cif, n_row, n_desf,
        lag(midx) OVER (PARTITION BY td, kv, cif ORDER BY midx) AS midx_prev
    FROM ent_mes
    WHERE s_neg > 0
),
mark AS (
    SELECT cmes, td, kv, cif, n_row, n_desf,
        CASE WHEN midx_prev IS NULL OR midx - midx_prev >= 3 THEN 1 ELSE 0 END AS es_alta
    FROM pos
    WHERE cmes BETWEEN '202304' AND '202312'
),
cli_mes AS (
    SELECT cmes, td, kv,
        sum(n_row)                                                     AS n_row,
        sum(n_desf)                                                    AS n_desf,
        sum(es_alta)                                                   AS n_ent_alta,
        min(CASE WHEN es_alta = 1 THEN cif END)                        AS cif_gana,
        max(CASE WHEN es_alta = 1 AND cif = '00002' THEN 1 ELSE 0 END) AS ibk_alta
    FROM mark
    GROUP BY 1,2,3
)
SELECT
    coalesce(cmes,'TOTAL')                                                  AS mes,
    count(*)                                                                AS n_cli_activo,
    sum(CASE WHEN n_ent_alta > 0 THEN 1 ELSE 0 END)                         AS n_cli_alta,
    sum(n_ent_alta)                                                         AS n_alta_ent,
    sum(CASE WHEN n_ent_alta > 1 THEN 1 ELSE 0 END)                         AS n_cli_multi,
    max(n_ent_alta)                                                         AS max_ent_alta,
    round(100.0 * sum(CASE WHEN n_ent_alta > 1 THEN 1 ELSE 0 END)
          / nullif(sum(CASE WHEN n_ent_alta > 0 THEN 1 ELSE 0 END), 0), 3)  AS pct_multi,
    sum(ibk_alta)                                                           AS n_ibk_alta,
    sum(CASE WHEN ibk_alta = 1 AND cif_gana < '00002' THEN 1 ELSE 0 END)    AS n_ibk_pierde,
    round(100.0 * sum(CASE WHEN ibk_alta = 1 AND cif_gana < '00002' THEN 1 ELSE 0 END)
          / nullif(sum(ibk_alta), 0), 3)                                    AS pct_ibk_pierde,
    sum(CASE WHEN n_ent_alta > 1 AND cif_gana = '00001' THEN 1 ELSE 0 END)  AS n_multi_gana_bcp,
    sum(CASE WHEN n_ent_alta > 1 AND cif_gana = '00002' THEN 1 ELSE 0 END)  AS n_multi_gana_ibk,
    sum(n_row)                                                              AS n_filas_neg,
    sum(n_desf)                                                             AS n_filas_pmes_ne_cmes
FROM cli_mes
GROUP BY GROUPING SETS ((cmes), ())
ORDER BY 1
