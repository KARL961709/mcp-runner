-- 20_hist.sql | ventanas hacia atras que alimentan los filtros de origen y de pasado, leidas de la capa agregada.
-- Replica el grano de produccion: castigo, judicial, refinanciado, reestructurado, bancarizacion y clasificacion se
-- miden a nivel CLIENTE sumando entidades (asi lo hace tmp_rcc_flg, que agrupa sin cod_instit_financiera), mientras
-- que la mora de tarjeta se mide a nivel ENTIDAD.
-- Los cinco filtros de origen se emiten DOS veces porque son CASO2 con reanclaje pendiente de firma:
--   _m0  como produccion, leyendo el RCC en el mes del alta
--   _m2  reanclado, leyendo el RCC en m-2, que es el ultimo mes publicado al momento del alta
-- Emitir ambas cuesta lo mismo y evita reconstruir para decidir. La diferencia entre las dos ES el delta que R11 pide
-- medir para firmar el reanclaje.
CREATE TABLE disc_model_owner.ds_adm_tcnb_20_hist
WITH (
    format              = 'PARQUET',
    parquet_compression = 'SNAPPY',
    partitioned_by      = ARRAY['codmes_mrm'],
    external_location   = '<S3_DATOS>/adm_tcnb_20_hist/'
) AS
WITH po AS (
    SELECT DISTINCT codmes_mrm, tip_doc, id_value, entidad,
           date_format(date_add('month',  -2, date_parse(codmes_mrm, '%Y%m')), '%Y%m') AS m02,
           date_format(date_add('month',  -7, date_parse(codmes_mrm, '%Y%m')), '%Y%m') AS m07,
           date_format(date_add('month', -13, date_parse(codmes_mrm, '%Y%m')), '%Y%m') AS m13,
           date_format(date_add('month', -25, date_parse(codmes_mrm, '%Y%m')), '%Y%m') AS m25
    FROM disc_model_owner.ds_adm_tcnb_10_po
),
cli AS (
    SELECT codmes, tip_doc, key_value,
           sum(monto_cast)     AS monto_cast,
           sum(sld_ref)        AS sld_ref,
           sum(sld_ree)        AS sld_ree,
           sum(sld_jud)        AS sld_jud,
           sum(sld_bank)       AS sld_bank,
           max(clasif_max)     AS clasif_max,
           max(flg_no_consumo) AS flg_no_consumo
    FROM disc_model_owner.ds_adm_tcnb_05_rcc_agg
    GROUP BY codmes, tip_doc, key_value
)
SELECT p.tip_doc,
       p.id_value,
       p.entidad,
       max(CASE WHEN c.codmes = p.codmes_mrm AND c.monto_cast > 0 THEN 1 ELSE 0 END)   AS f_cast_ori_m0,
       max(CASE WHEN c.codmes = p.m02        AND c.monto_cast > 0 THEN 1 ELSE 0 END)   AS f_cast_ori_m2,
       max(CASE WHEN c.codmes = p.codmes_mrm AND c.sld_jud    > 0 THEN 1 ELSE 0 END)   AS f_jud_ori_m0,
       max(CASE WHEN c.codmes = p.m02        AND c.sld_jud    > 0 THEN 1 ELSE 0 END)   AS f_jud_ori_m2,
       max(CASE WHEN c.codmes = p.codmes_mrm AND c.sld_ref    > 0 THEN 1 ELSE 0 END)   AS f_ref_ori_m0,
       max(CASE WHEN c.codmes = p.m02        AND c.sld_ref    > 0 THEN 1 ELSE 0 END)   AS f_ref_ori_m2,
       max(CASE WHEN c.codmes = p.codmes_mrm AND c.sld_ree    > 0 THEN 1 ELSE 0 END)   AS f_ree_ori_m0,
       max(CASE WHEN c.codmes = p.m02        AND c.sld_ree    > 0 THEN 1 ELSE 0 END)   AS f_ree_ori_m2,
       max(CASE WHEN e.codmes = p.codmes_mrm AND e.dm_tc      > 0 THEN 1 ELSE 0 END)   AS f_malo_ori_m0,
       max(CASE WHEN e.codmes = p.m02        AND e.dm_tc      > 0 THEN 1 ELSE 0 END)   AS f_malo_ori_m2,
       max(CASE WHEN c.codmes BETWEEN p.m25 AND p.m02 AND c.monto_cast > 0 THEN 1 ELSE 0 END) AS f_cast_u24m,
       max(CASE WHEN c.codmes BETWEEN p.m25 AND p.m02 AND c.sld_jud    > 0 THEN 1 ELSE 0 END) AS f_jud_u24m,
       max(CASE WHEN c.codmes BETWEEN p.m07 AND p.m02 AND c.sld_ref    > 0 THEN 1 ELSE 0 END) AS f_ref_u6m,
       max(CASE WHEN c.codmes BETWEEN p.m13 AND p.m02 AND c.sld_bank   > 0 THEN 1 ELSE 0 END) AS f_banc_u12m,
       max(CASE WHEN c.codmes = p.m02 AND c.clasif_max IN ('2','3','4') THEN 1 ELSE 0 END)    AS f_mayor_cpp,
       max(CASE WHEN c.codmes BETWEEN p.m25 AND p.m02 AND c.flg_no_consumo = 1 THEN 1 ELSE 0 END) AS ctrl_no_consumo,
       CAST(CASE WHEN max(CASE WHEN c.codmes IS NOT NULL THEN 1 ELSE 0 END) = 0
                 THEN 1 ELSE 0 END AS INTEGER)                                         AS falla_sin_historia,
       p.codmes_mrm
FROM po p
LEFT JOIN cli c
       ON c.tip_doc = p.tip_doc AND c.key_value = p.id_value
      AND c.codmes BETWEEN p.m25 AND p.codmes_mrm
LEFT JOIN disc_model_owner.ds_adm_tcnb_05_rcc_agg e
       ON e.tip_doc = p.tip_doc AND e.key_value = p.id_value AND e.entidad = p.entidad
      AND e.codmes BETWEEN p.m25 AND p.codmes_mrm
GROUP BY p.tip_doc, p.id_value, p.entidad, p.codmes_mrm
