-- 30_fut.sql | ventana futura m+1 a m+12, el insumo del target. La mora de tarjeta va a nivel ENTIDAD y el evento duro
-- (castigo, judicial, refinanciado, reestructurado) a nivel CLIENTE, igual que en produccion.
-- missing_12 cuenta los meses SIN observacion de la entidad en la capa agregada: 12 menos los meses distintos vistos.
-- No se usa la regla missing_12 > 6 como proxy de madurez. La madurez se decide en 35_target con la frontera real del
-- RCC, porque esa regla publica etiquetas de 12 meses armadas con 6 meses observados (medido: desde 202509 ningun
-- registro tiene el mes 12, y en 202603 a 202605 la tasa de malos publicada sale 100 por ciento).
CREATE TABLE disc_model_owner.ds_adm_tcnb_30_fut
WITH (
    format              = 'PARQUET',
    parquet_compression = 'SNAPPY',
    partitioned_by      = ARRAY['codmes_mrm'],
    external_location   = '<S3_DATOS>/adm_tcnb_30_fut/'
) AS
WITH po AS (
    SELECT DISTINCT codmes_mrm, tip_doc, id_value, entidad,
           date_format(date_add('month',  1, date_parse(codmes_mrm, '%Y%m')), '%Y%m') AS p01,
           date_format(date_add('month', 12, date_parse(codmes_mrm, '%Y%m')), '%Y%m') AS p12
    FROM disc_model_owner.ds_adm_tcnb_10_po
),
cli AS (
    SELECT codmes, tip_doc, key_value,
           sum(monto_cast) AS monto_cast,
           sum(sld_ref)    AS sld_ref,
           sum(sld_ree)    AS sld_ree,
           sum(sld_jud)    AS sld_jud
    FROM disc_model_owner.ds_adm_tcnb_05_rcc_agg
    GROUP BY codmes, tip_doc, key_value
)
SELECT p.tip_doc,
       p.id_value,
       p.entidad,
       max(e.dm_tc)                                                                    AS max_dm_fut,
       CAST(12 - count(DISTINCT e.codmes) AS INTEGER)                                  AS missing_12,
       max(CASE WHEN c.monto_cast > 0 THEN 1 ELSE 0 END)                               AS f_cast_fut,
       max(CASE WHEN c.sld_jud    > 0 THEN 1 ELSE 0 END)                               AS f_jud_fut,
       max(CASE WHEN c.sld_ref    > 0 THEN 1 ELSE 0 END)                               AS f_ref_fut,
       max(CASE WHEN c.sld_ree    > 0 THEN 1 ELSE 0 END)                               AS f_ree_fut,
       p.codmes_mrm
FROM po p
LEFT JOIN disc_model_owner.ds_adm_tcnb_05_rcc_agg e
       ON e.tip_doc = p.tip_doc AND e.key_value = p.id_value AND e.entidad = p.entidad
      AND e.codmes BETWEEN p.p01 AND p.p12
LEFT JOIN cli c
       ON c.tip_doc = p.tip_doc AND c.key_value = p.id_value
      AND c.codmes BETWEEN p.p01 AND p.p12
GROUP BY p.tip_doc, p.id_value, p.entidad, p.codmes_mrm
