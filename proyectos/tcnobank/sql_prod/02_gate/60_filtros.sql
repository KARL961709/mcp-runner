-- 60_filtros.sql | evalua los 20 filtros de la PO, UNO POR COLUMNA. Ninguno se funde en una cascada: el n de una
-- cascada mide el residual y no el filtro, y medido dio entre 6 y 25 veces menos que el aislado (q91 contra q05).
-- Cada filtro vale 1 si excluye y 0 si pasa, nunca NULL.
-- EJES SEPARADOS, un flag una pregunta:
--   f_edad_rango   edad fuera de 21 a 75, medida sobre fec_nacimiento que es inmutable
--   f_edad_nomatch sin fila en RENIEC. NO es criterio de admision sino hueco de dato, va a disponibilidad
--   Produccion los funde: NULL BETWEEN 21 AND 75 cae al ELSE 0 y ambos salen como EDAD. La q96 midio el corte real
--   en el bucket, cerca de mitad y mitad, no 82 a 18 como estime con el score viejo.
-- ANCLAJE de los CASO2 con fuente rezagada: fraude a p_codmes menor o igual a m-2 (la q93 probo que la tabla es delta
--   sin reversiones, asi que el acumulado es correcto) y garantia y convenio a m-2.
-- Los cinco de origen llegan en las dos variantes desde 20_hist y aca se elige _m2, que es la honesta. La _m0 queda
--   disponible en 20_hist para medir el delta del reanclaje.
CREATE TABLE disc_model_owner.ds_adm_tcnb_60_filtros
WITH (
    format              = 'PARQUET',
    parquet_compression = 'SNAPPY',
    partitioned_by      = ARRAY['codmes_mrm'],
    external_location   = '<S3_DATOS>/adm_tcnb_60_filtros/'
) AS
WITH po AS (
    SELECT codmes_mrm, tip_doc, id_value, entidad, prelacion_cod, prelacion_sld, saldo_tc_ori,
           date_format(date_add('month', -2, date_parse(codmes_mrm, '%Y%m')), '%Y%m') AS m02,
           date_format(date_add('month', 12, date_parse(codmes_mrm, '%Y%m')), '%Y%m') AS p12
    FROM disc_model_owner.ds_adm_tcnb_10_po
),
rn AS (
    SELECT tip_doc, key_value, fec_nacimiento FROM e_perm_aws.t_mst_reniec_rsk
),
sbs AS (
    SELECT tip_doc, key_value, sbs_value FROM (
        SELECT tip_doc, key_value, sbs_value,
               row_number() OVER (PARTITION BY tip_doc, key_value ORDER BY fch_creacion DESC) AS rn
        FROM e_perm_aws.t_mst_ctarcc_rsk) x
    WHERE x.rn = 1
),
gar AS (
    SELECT p_codmes, sbs_value,
           max(CASE WHEN cons_salgarhip > 0 THEN 1 ELSE 0 END)                          AS f_gar,
           max(CASE WHEN cons_salprestnorevconv > 0 OR cons_salprestrevconv > 0
                      OR cons_salpresconvob    > 0 THEN 1 ELSE 0 END)                   AS f_conv
    FROM e_perm_aws.t_consolidado_rsk
    GROUP BY p_codmes, sbs_value
),
fra AS (
    SELECT tip_doc, key_value, min(p_codmes) AS p_codmes_min
    FROM e_perm_aws.t_mst_fraude_rsk
    GROUP BY tip_doc, key_value
),
cuc AS (
    SELECT tip_doc, key_value, cod_cuc FROM (
        SELECT tip_doc, key_value, cod_cuc,
               row_number() OVER (PARTITION BY tip_doc, key_value ORDER BY cod_cuc DESC, fch_pricont DESC) AS rn
        FROM e_perm_aws.t_mst_ctaibk_rsk) x
    WHERE x.rn = 1
),
fac AS (
    SELECT codunicocli, CAST(periodo AS VARCHAR) AS codmes,
           max(CASE WHEN facilidad = 'SWAP' THEN 1 ELSE 0 END)                          AS f_swap,
           max(CASE WHEN facilidad = 'REPROGRAMACION'
                     AND tipo_facilidad IN ('LLUVIAS','UNILATERAL_LLUVIAS','SOCIAL') THEN 1 ELSE 0 END) AS f_repro
    FROM e_perm_aws.t_cob_facilidades_ejecutadas
    WHERE estado_facilidad = 'EJECUTADO'
    GROUP BY codunicocli, CAST(periodo AS VARCHAR)
)
SELECT p.tip_doc,
       p.id_value,
       p.entidad,
       p.prelacion_cod,
       p.prelacion_sld,
       p.saldo_tc_ori,
       CAST(CASE WHEN r.key_value IS NOT NULL AND r.fec_nacimiento IS NOT NULL
                  AND NOT (date_diff('year', CAST(r.fec_nacimiento AS DATE),
                                     CAST(date_parse(p.codmes_mrm || '01', '%Y%m%d') AS DATE)) BETWEEN 21 AND 75)
                 THEN 1 ELSE 0 END AS INTEGER)                                          AS f_edad_rango,
       CAST(CASE WHEN r.key_value IS NULL OR r.fec_nacimiento IS NULL
                 THEN 1 ELSE 0 END AS INTEGER)                                          AS f_edad_nomatch,
       CAST(h.f_banc_u12m  AS INTEGER)                                                  AS f_banc_u12m,
       CAST(h.f_cast_ori_m2 AS INTEGER)                                                 AS f_cast_ori,
       CAST(h.f_jud_ori_m2  AS INTEGER)                                                 AS f_jud_ori,
       CAST(h.f_ref_ori_m2  AS INTEGER)                                                 AS f_ref_ori,
       CAST(h.f_ree_ori_m2  AS INTEGER)                                                 AS f_ree_ori,
       CAST(h.f_malo_ori_m2 AS INTEGER)                                                 AS f_malo_ori,
       CAST(h.f_cast_u24m  AS INTEGER)                                                  AS f_cast_u24m,
       CAST(h.f_jud_u24m   AS INTEGER)                                                  AS f_jud_u24m,
       CAST(h.f_ref_u6m    AS INTEGER)                                                  AS f_ref_u6m,
       CAST(h.f_mayor_cpp  AS INTEGER)                                                  AS f_mayor_cpp,
       CAST(coalesce(greatest(g.f_gar, g.f_conv), 0) AS INTEGER)                        AS f_gar_conv,
       CAST(CASE WHEN fr.p_codmes_min IS NOT NULL AND fr.p_codmes_min <= p.m02
                 THEN 1 ELSE 0 END AS INTEGER)                                          AS f_fraude,
       CAST(CASE WHEN p.entidad NOT IN ('00001','00002','00004','00006','00142')
                 THEN 1 ELSE 0 END AS INTEGER)                                          AS f_entidades,
       CAST(coalesce(su.f_swap,  0) AS INTEGER)                                         AS f_swap_u12m,
       CAST(coalesce(sp.f_swap,  0) AS INTEGER)                                         AS f_swap_p12m,
       CAST(coalesce(sp.f_repro, 0) AS INTEGER)                                         AS f_repro_p12m,
       CAST(CASE WHEN p.codmes_mrm < '202106' THEN 1 ELSE 0 END AS INTEGER)             AS ctrl_sin_fraude,
       CAST(CASE WHEN p.codmes_mrm < '202201' THEN 1 ELSE 0 END AS INTEGER)             AS ctrl_sin_swap,
       CAST(CASE WHEN c.cod_cuc IS NULL THEN 1 ELSE 0 END AS INTEGER)                   AS falla_sin_cuc,
       CAST(CASE WHEN s.sbs_value IS NULL THEN 1 ELSE 0 END AS INTEGER)                 AS falla_sin_sbs,
       CAST(h.falla_sin_historia AS INTEGER)                                            AS falla_sin_historia,
       p.codmes_mrm
FROM po p
LEFT JOIN disc_model_owner.ds_adm_tcnb_20_hist h ON h.tip_doc = p.tip_doc AND h.id_value = p.id_value
                         AND h.entidad = p.entidad AND h.codmes_mrm = p.codmes_mrm
LEFT JOIN rn  r  ON r.tip_doc = p.tip_doc AND r.key_value = p.id_value
LEFT JOIN sbs s  ON s.tip_doc = p.tip_doc AND s.key_value = p.id_value
LEFT JOIN gar g  ON g.sbs_value = s.sbs_value AND g.p_codmes = p.m02
LEFT JOIN fra fr ON fr.tip_doc = p.tip_doc AND fr.key_value = p.id_value
LEFT JOIN cuc c  ON c.tip_doc = p.tip_doc AND c.key_value = p.id_value
LEFT JOIN (SELECT codunicocli, codmes, f_swap FROM fac) su
       ON su.codunicocli = c.cod_cuc
      AND su.codmes BETWEEN date_format(date_add('month', -12, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m')
                        AND date_format(date_add('month',  -1, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m')
LEFT JOIN (SELECT codunicocli, codmes, f_swap, f_repro FROM fac) sp
       ON sp.codunicocli = c.cod_cuc
      AND sp.codmes BETWEEN date_format(date_add('month', 1, date_parse(p.codmes_mrm, '%Y%m')), '%Y%m')
                        AND p.p12
