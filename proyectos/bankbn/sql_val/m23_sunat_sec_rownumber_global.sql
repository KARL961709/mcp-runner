-- m23_sunat_sec_rownumber_global.sql | tamano real del window sin podar de t_mst_sec_sunat_rsk y si num=1 deja un solo ruc_value: decide si 2t1_f_mad_sunat.sql:59-62 hace fan-out y si hay que podar antes del ROW_NUMBER
WITH par AS (
    SELECT
        tip_doc,
        key_value,
        count(*)                  AS n_fil,
        count(DISTINCT ruc_value) AS n_ruc,
        min(ruc_value)            AS ruc_min
    FROM e_perm_aws.t_mst_sec_sunat_rsk
    GROUP BY 1, 2
),
sel AS (
    SELECT
        ruc_min                                    AS ruc,
        count(*)                                   AS n_par,
        sum(n_fil)                                 AS n_fil,
        max(n_fil)                                 AS max_fil,
        sum(CASE WHEN n_fil > 1 THEN 1 ELSE 0 END) AS n_par_multifila,
        sum(CASE WHEN n_ruc > 1 THEN 1 ELSE 0 END) AS n_par_multiruc,
        max(n_ruc)                                 AS max_ruc
    FROM par
    GROUP BY 1
),
buk AS (
    SELECT
        CASE WHEN ruc IS NULL OR trim(cast(ruc AS varchar)) = '' THEN '0_ruc_nulo_vacio'
             WHEN n_par = 1  THEN '1_sin_fanout'
             WHEN n_par = 2  THEN '2_fanout_x2'
             WHEN n_par <= 10 THEN '3_fanout_x3_x10'
             ELSE '4_fanout_x11_mas' END AS bkt,
        n_par,
        n_fil,
        max_fil,
        n_par_multifila,
        n_par_multiruc,
        max_ruc
    FROM sel
)
SELECT
    coalesce(bkt, 'Z_TOTAL')                           AS bucket,
    count(*)                                           AS rucs,
    sum(n_par)                                         AS filas_num1,
    sum(n_fil)                                         AS filas_sec_escaneadas,
    max(n_par)                                         AS max_num1_por_ruc,
    sum(CASE WHEN n_par > 1 THEN n_par - 1 ELSE 0 END) AS filas_extra_por_fanout,
    sum(n_par_multifila)                               AS pares_con_mas_de_1_fila,
    max(max_fil)                                       AS max_filas_por_par,
    sum(n_par_multiruc)                                AS pares_con_mas_de_1_ruc,
    max(max_ruc)                                       AS max_rucs_por_par
FROM buk
GROUP BY ROLLUP (bkt)
ORDER BY 1
