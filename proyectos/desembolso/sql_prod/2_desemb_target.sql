-- 2_desemb_target.sql | tabla NUEVA disc_model_owner.b46029_desemb_target_202609: target_01m..target_12m para user_desembolso, malo (f2_mad: condicion(dm)>90 o judicial/castigo/refinanciado/reestructurado) en la ventana [cod_mes+1, cod_mes+h] medido en entidad IBK (cod_instit_financiera 00002) via RCC. FRONTERA DINAMICA: fr = max codmes con datos en la RCC, y target_hm = NULL cuando el fin de ventana (cod_mes+h) se pasa de fr (horizonte no cerrado, no se censura como 0). meses_madurez = min(12, meses de cod_mes a fr). Grano cliente-mes, target acumulado y monotono
CREATE TABLE disc_model_owner.b46029_desemb_target_202609
WITH (format = 'PARQUET', parquet_compression = 'SNAPPY') AS
WITH front AS (
  SELECT max(cast(codmes AS int)) AS fr
  FROM e_perm_aws.t_fact_report_rcc_rsk
  WHERE codmes BETWEEN '202302' AND '202612'
),
altas AS (
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
  WHERE r.cod_instit_financiera = '00002' AND r.p_codmes BETWEEN '202302' AND '202612' AND r.codmes BETWEEN '202302' AND '202612'
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
),
agg AS (
  SELECT j.cm, j.td, j.kv, f.fr,
    max(j.w1) AS mw1, max(j.w2) AS mw2, max(j.w3) AS mw3, max(j.w4) AS mw4, max(j.w5) AS mw5, max(j.w6) AS mw6,
    max(j.w7) AS mw7, max(j.w8) AS mw8, max(j.w9) AS mw9, max(j.w10) AS mw10, max(j.w11) AS mw11, max(j.w12) AS mw12,
    max(CASE WHEN j.rcm BETWEEN j.w1 AND j.w1  THEN j.bad ELSE 0 END) AS t01,
    max(CASE WHEN j.rcm BETWEEN j.w1 AND j.w2  THEN j.bad ELSE 0 END) AS t02,
    max(CASE WHEN j.rcm BETWEEN j.w1 AND j.w3  THEN j.bad ELSE 0 END) AS t03,
    max(CASE WHEN j.rcm BETWEEN j.w1 AND j.w4  THEN j.bad ELSE 0 END) AS t04,
    max(CASE WHEN j.rcm BETWEEN j.w1 AND j.w5  THEN j.bad ELSE 0 END) AS t05,
    max(CASE WHEN j.rcm BETWEEN j.w1 AND j.w6  THEN j.bad ELSE 0 END) AS t06,
    max(CASE WHEN j.rcm BETWEEN j.w1 AND j.w7  THEN j.bad ELSE 0 END) AS t07,
    max(CASE WHEN j.rcm BETWEEN j.w1 AND j.w8  THEN j.bad ELSE 0 END) AS t08,
    max(CASE WHEN j.rcm BETWEEN j.w1 AND j.w9  THEN j.bad ELSE 0 END) AS t09,
    max(CASE WHEN j.rcm BETWEEN j.w1 AND j.w10 THEN j.bad ELSE 0 END) AS t10,
    max(CASE WHEN j.rcm BETWEEN j.w1 AND j.w11 THEN j.bad ELSE 0 END) AS t11,
    max(CASE WHEN j.rcm BETWEEN j.w1 AND j.w12 THEN j.bad ELSE 0 END) AS t12
  FROM j CROSS JOIN front f
  GROUP BY j.cm, j.td, j.kv, f.fr
)
SELECT cm AS cod_mes, td AS cod_tip_doc, kv AS key_value,
  CASE WHEN mw1  <= fr THEN t01 END AS target_01m,
  CASE WHEN mw2  <= fr THEN t02 END AS target_02m,
  CASE WHEN mw3  <= fr THEN t03 END AS target_03m,
  CASE WHEN mw4  <= fr THEN t04 END AS target_04m,
  CASE WHEN mw5  <= fr THEN t05 END AS target_05m,
  CASE WHEN mw6  <= fr THEN t06 END AS target_06m,
  CASE WHEN mw7  <= fr THEN t07 END AS target_07m,
  CASE WHEN mw8  <= fr THEN t08 END AS target_08m,
  CASE WHEN mw9  <= fr THEN t09 END AS target_09m,
  CASE WHEN mw10 <= fr THEN t10 END AS target_10m,
  CASE WHEN mw11 <= fr THEN t11 END AS target_11m,
  CASE WHEN mw12 <= fr THEN t12 END AS target_12m,
  greatest(0, least(12, date_diff('month', date_parse(cast(cm AS varchar),'%Y%m'), date_parse(cast(fr AS varchar),'%Y%m')))) AS meses_madurez,
  fr AS rcc_frontera
FROM agg
