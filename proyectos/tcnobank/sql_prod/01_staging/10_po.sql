-- 10_po.sql | poblacion: alta de TC derivada del propio RCC, definida como tarjeta presente en el mes y ausente en los
-- 12 previos, al grano cliente x entidad. Se deriva del RCC y no de tng_altas por dos razones medidas: la q82 dio
-- recall de 99.83 a 99.99 por ciento contra tng_altas en las siete entidades con volumen, y para SSFF no existe otra
-- fuente de alta, asi que es la unica regla aplicable igual a las doce entidades y a los 77 meses. Solo IBK cae a
-- 74.38 por ciento, porque tng_altas_ibk sale del sistema de originacion interno y no del RCC: queda como desviacion
-- firmada, con la causa identificada (rezago de reporte al RCC).
-- DEDUP: se emiten las DOS prelaciones porque la decision no esta tomada y emitir ambas cuesta lo mismo.
--   prelacion_cod  replica produccion (entidad ASC) y da prioridad sistematica a BCP por su numeracion SBS
--   prelacion_sld  ordena por saldo de tarjeta, que es el criterio economico
-- Ninguna mira el target: las prelaciones de produccion a 6, 9 y 12 meses ordenan por flg_cc_default_desc, y eso es
-- look-ahead en la seleccion de la fila.
CREATE TABLE disc_model_owner.ds_adm_tcnb_10_po
WITH (
    format              = 'PARQUET',
    parquet_compression = 'SNAPPY',
    partitioned_by      = ARRAY['codmes_mrm'],
    external_location   = '<S3_DATOS>/adm_tcnb_10_po/'
) AS
WITH tc AS (
    SELECT codmes, tip_doc, key_value, entidad, saldo_tc
    FROM disc_model_owner.ds_adm_tcnb_05_rcc_agg
    WHERE flg_tc = 1
),
alta AS (
    SELECT a.codmes, a.tip_doc, a.key_value, a.entidad, a.saldo_tc
    FROM tc a
    LEFT JOIN tc b
           ON b.tip_doc   = a.tip_doc
          AND b.key_value = a.key_value
          AND b.entidad   = a.entidad
          AND b.codmes   >= date_format(date_add('month', -12, date_parse(a.codmes, '%Y%m')), '%Y%m')
          AND b.codmes   <= date_format(date_add('month',  -1, date_parse(a.codmes, '%Y%m')), '%Y%m')
    WHERE a.codmes BETWEEN '201902' AND '202506'
      AND b.key_value IS NULL
)
SELECT tip_doc,
       key_value                                                                       AS id_value,
       entidad,
       saldo_tc                                                                        AS saldo_tc_ori,
       CAST(row_number() OVER (PARTITION BY codmes, tip_doc, key_value
                               ORDER BY entidad ASC, saldo_tc DESC) AS INTEGER)        AS prelacion_cod,
       CAST(row_number() OVER (PARTITION BY codmes, tip_doc, key_value
                               ORDER BY saldo_tc DESC, entidad ASC) AS INTEGER)        AS prelacion_sld,
       codmes                                                                          AS codmes_mrm
FROM alta
