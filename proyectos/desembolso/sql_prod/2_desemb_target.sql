-- 2_desemb_target.sql | tabla NUEVA disc_model_owner.b46029_desemb_target_202609: target_01m..target_12m para user_desembolso, malo (definicion f2_mad: condicion(dm)>90 o judicial/castigo/refinanciado/reestructurado) en la ventana [cod_mes+1, cod_mes+h] medido en la entidad IBK (cod_instit_financiera 00002) via RCC. Grano cliente-mes (cod_mes x cod_tip_doc x key_value). target acumulado y monotono. meses_madurez = cuantos de los 12 ya se observan con RCC cerrada a 202608 (cohortes recientes quedan inmaduras, su target_h para h mayor a meses_madurez es parcial)
CREATE TABLE disc_model_owner.b46029_desemb_target_202609
WITH (format = 'PARQUET', parquet_compression = 'SNAPPY') AS
WITH altas AS (
  SELECT DISTINCT cast(cod_mes AS int) AS cm, cod_tip_doc AS td, key_value AS kv
  FROM d_perm_aws.user_desembolso
),
uni AS ( SELECT DISTINCT td, kv FROM altas ),
dr AS (
  SELECT cast(r.codmes AS int) AS rcm, r.tip_doc AS td, r.key_value AS kv,
    max(CASE WHEN cast(r.tipo_credito AS int) BETWEEN 1 AND 10
             AND ((substr(r.cod_cuenta_rcc,1,2)='14' AND substr(r.cod_cuenta_rcc,7,2) NOT IN ('01','04') AND substr(r.cod_cuenta_rcc,4,1) IN ('1','3','4','5','6'))
               OR (substr(r.cod_cuenta_rcc,1,2)='81' AND substr(r.cod_cuenta_rcc,4,3) IN ('302','925')))
             THEN TRY_CAST(r.condicion AS int) ELSE null END) AS dm,
    max(CASE WHEN substr(r.cod_cuenta_rcc,1,2)='14' AND substr(r.cod_cuenta_rcc,4,1)='3' AND cast(r.tipo_credito AS int) BETWEEN 1 AND 10 THEN 1 ELSE 0 END) AS ree,
    max(CASE WHEN substr(r.cod_cuenta_rcc,1,2)='14' AND substr(r.cod_cuenta_rcc,4,1)='4' AND cast(r.tipo_credito AS int) BETWEEN 1 AND 10 THEN 1 ELSE 0 END) AS ref,
    max(CASE WHEN substr(r.cod_cuenta_rcc,1,2)='14' AND substr(r.cod_cuenta_rcc,4,1)='6' AND cast(r.tipo_credito AS int) BETWEEN 1 AND 10 THEN 1 ELSE 0 END) AS jud,
    max(CASE WHEN substr(r.cod_cuenta_rcc,1,2)='81' AND substr(r.cod_cuenta_rcc,4,3) IN ('302','925') AND cast(r.tipo_credito AS int) BETWEEN 1 AND 10 THEN 1 ELSE 0 END) AS cst
  FROM e_perm_aws.t_fact_report_rcc_rsk r
  INNER JOIN uni u ON u.td = r.tip_doc AND u.kv = r.key_value
  WHERE r.cod_instit_financiera = '00002' AND r.p_codmes BETWEEN '202302' AND '202608' AND r.codmes BETWEEN '202302' AND '202608'
  GROUP BY cast(r.codmes AS int), r.tip_doc, r.key_value
),
j AS (
  SELECT a.cm, a.td, a.kv, d.rcm,
    cast(date_format(date_parse(cast(a.cm AS varchar),'%Y%m') + interval '1'  month,'%Y%m') AS int) AS w1,
    cast(date_format(date_parse(cast(a.cm AS varchar),'%Y%m') + interval '2'  month,'%Y%m') AS int) AS w2,
    cast(date_format(date_parse(cast(a.cm AS varchar),'%Y%m') + interval '3'  month,'%Y%m') AS int) AS w3,
    cast(date_format(date_parse(cast(a.cm AS varchar),'%Y%m') + interval '4'  month,'%Y%m') AS int) AS w4,
    cast(date_format(date_parse(cast(a.cm AS varchar),'%Y%m') + interval '5'  month,'%Y%m') AS int) AS w5,
    cast(date_format(date_parse(cast(a.cm AS varchar),'%Y%m') + interval '6'  month,'%Y%m') AS int) AS w6,
    cast(date_format(date_parse(cast(a.cm AS varchar),'%Y%m') + interval '7'  month,'%Y%m') AS int) AS w7,
    cast(date_format(date_parse(cast(a.cm AS varchar),'%Y%m') + interval '8'  month,'%Y%m') AS int) AS w8,
    cast(date_format(date_parse(cast(a.cm AS varchar),'%Y%m') + interval '9'  month,'%Y%m') AS int) AS w9,
    cast(date_format(date_parse(cast(a.cm AS varchar),'%Y%m') + interval '10' month,'%Y%m') AS int) AS w10,
    cast(date_format(date_parse(cast(a.cm AS varchar),'%Y%m') + interval '11' month,'%Y%m') AS int) AS w11,
    cast(date_format(date_parse(cast(a.cm AS varchar),'%Y%m') + interval '12' month,'%Y%m') AS int) AS w12,
    CASE WHEN d.dm > 90 OR d.jud = 1 OR d.cst = 1 OR d.ref = 1 OR d.ree = 1 THEN 1 ELSE 0 END AS bad
  FROM altas a
  LEFT JOIN dr d ON d.td = a.td AND d.kv = a.kv
)
SELECT cm AS cod_mes, td AS cod_tip_doc, kv AS key_value,
  max(CASE WHEN rcm BETWEEN w1 AND w1  THEN bad ELSE 0 END) AS target_01m,
  max(CASE WHEN rcm BETWEEN w1 AND w2  THEN bad ELSE 0 END) AS target_02m,
  max(CASE WHEN rcm BETWEEN w1 AND w3  THEN bad ELSE 0 END) AS target_03m,
  max(CASE WHEN rcm BETWEEN w1 AND w4  THEN bad ELSE 0 END) AS target_04m,
  max(CASE WHEN rcm BETWEEN w1 AND w5  THEN bad ELSE 0 END) AS target_05m,
  max(CASE WHEN rcm BETWEEN w1 AND w6  THEN bad ELSE 0 END) AS target_06m,
  max(CASE WHEN rcm BETWEEN w1 AND w7  THEN bad ELSE 0 END) AS target_07m,
  max(CASE WHEN rcm BETWEEN w1 AND w8  THEN bad ELSE 0 END) AS target_08m,
  max(CASE WHEN rcm BETWEEN w1 AND w9  THEN bad ELSE 0 END) AS target_09m,
  max(CASE WHEN rcm BETWEEN w1 AND w10 THEN bad ELSE 0 END) AS target_10m,
  max(CASE WHEN rcm BETWEEN w1 AND w11 THEN bad ELSE 0 END) AS target_11m,
  max(CASE WHEN rcm BETWEEN w1 AND w12 THEN bad ELSE 0 END) AS target_12m,
  greatest(0, least(12, date_diff('month', date_parse(cast(cm AS varchar),'%Y%m'), date_parse('202608','%Y%m')))) AS meses_madurez
FROM j
GROUP BY cm, td, kv
