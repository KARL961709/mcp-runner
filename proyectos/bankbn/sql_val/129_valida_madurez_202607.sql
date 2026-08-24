-- 129_valida_madurez_202607.sql | re-madura las cohortes IBK 2025 con RCC cerrado a 202607 y valida vs lo proyectado. Replica el target de f2_mad: en la ventana [alta+1, alta+12] y en la entidad del alta, malo si condicion(dm)>90 o judicial/castigo/refinanciado/reestructurado. rd_hasta_202606 es sanity (debe calzar con el ds); rd_hasta_202607 usa el mes nuevo. Con 202607, la cohorte 202507 madura a h12. READ-ONLY
WITH altas AS (
  SELECT cast(c.codmes AS int) AS cm, c.tip_doc, c.key_value, c.cod_instit_financiera AS ent,
         CASE WHEN c.flg_ppjj = 1 THEN 'PJJ' ELSE 'PNN' END AS per
  FROM disc_model_owner.ds_adm_bpe_bankbn_cal_202607 c
  WHERE c.entidad = 'IBK' AND c.flg_clean_calib <> 99 AND cast(c.codmes AS int) BETWEEN 202501 AND 202512
),
uni AS ( SELECT DISTINCT tip_doc, key_value FROM altas ),
dr AS (
  SELECT cast(r.codmes AS int) AS rcm, r.tip_doc, r.key_value, r.cod_instit_financiera AS ent,
    max(CASE WHEN cast(r.tipo_credito AS int) BETWEEN 1 AND 10
             AND ((substr(r.cod_cuenta_rcc,1,2)='14' AND substr(r.cod_cuenta_rcc,7,2) NOT IN ('01','04') AND substr(r.cod_cuenta_rcc,4,1) IN ('1','3','4','5','6'))
               OR (substr(r.cod_cuenta_rcc,1,2)='81' AND substr(r.cod_cuenta_rcc,4,3) IN ('302','925')))
             THEN TRY_CAST(r.condicion AS int) ELSE null END) AS dm,
    max(CASE WHEN substr(r.cod_cuenta_rcc,1,2)='14' AND substr(r.cod_cuenta_rcc,4,1)='3' AND cast(r.tipo_credito AS int) BETWEEN 1 AND 10 THEN 1 ELSE 0 END) AS ree,
    max(CASE WHEN substr(r.cod_cuenta_rcc,1,2)='14' AND substr(r.cod_cuenta_rcc,4,1)='4' AND cast(r.tipo_credito AS int) BETWEEN 1 AND 10 THEN 1 ELSE 0 END) AS ref,
    max(CASE WHEN substr(r.cod_cuenta_rcc,1,2)='14' AND substr(r.cod_cuenta_rcc,4,1)='6' AND cast(r.tipo_credito AS int) BETWEEN 1 AND 10 THEN 1 ELSE 0 END) AS jud,
    max(CASE WHEN substr(r.cod_cuenta_rcc,1,2)='81' AND substr(r.cod_cuenta_rcc,4,3) IN ('302','925') AND cast(r.tipo_credito AS int) BETWEEN 1 AND 10 THEN 1 ELSE 0 END) AS cst
  FROM e_perm_aws.t_fact_report_rcc_rsk r
  INNER JOIN uni u ON u.tip_doc = r.tip_doc AND u.key_value = r.key_value
  WHERE r.p_codmes BETWEEN '202502' AND '202607' AND r.codmes BETWEEN '202502' AND '202607'
  GROUP BY cast(r.codmes AS int), r.tip_doc, r.key_value, r.cod_instit_financiera
),
j AS (
  SELECT a.per, a.cm, a.tip_doc, a.key_value,
    cast(date_format(date_parse(cast(a.cm AS varchar),'%Y%m') + interval '1'  month,'%Y%m') AS int) AS w1,
    cast(date_format(date_parse(cast(a.cm AS varchar),'%Y%m') + interval '12' month,'%Y%m') AS int) AS w12,
    d.rcm,
    CASE WHEN d.dm > 90 OR d.jud = 1 OR d.cst = 1 OR d.ref = 1 OR d.ree = 1 THEN 1 ELSE 0 END AS bad
  FROM altas a
  LEFT JOIN dr d ON d.tip_doc = a.tip_doc AND d.key_value = a.key_value AND d.ent = a.ent
),
cli AS (
  SELECT per, cm, tip_doc, key_value,
    max(CASE WHEN rcm BETWEEN w1 AND w12 AND rcm <= 202606 THEN bad ELSE 0 END) AS bad_206,
    max(CASE WHEN rcm BETWEEN w1 AND w12 AND rcm <= 202607 THEN bad ELSE 0 END) AS bad_207
  FROM j GROUP BY per, cm, tip_doc, key_value
)
SELECT per, cm AS codmes,
  date_diff('month', date_parse(cast(cm AS varchar),'%Y%m'), date_parse('202607','%Y%m')) AS h_al_202607,
  count(*) AS n,
  round(100.0 * avg(bad_206), 3) AS rd_hasta_202606,
  round(100.0 * avg(bad_207), 3) AS rd_hasta_202607
FROM cli
GROUP BY per, cm
ORDER BY per, cm
