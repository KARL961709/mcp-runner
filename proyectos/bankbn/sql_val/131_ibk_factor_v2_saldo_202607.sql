-- 131_ibk_factor_v2_saldo_202607.sql | factor anti-conservador CORRECTO para v2 en IBK: RD real re-madurada con RCC cerrado a 202607 (incluye la cohorte 202507 ya cerrada), PONDERADA POR saldo_m0_ent (exposicion IBK), contra la PD v2 (prob_modelo_cal_v2 de la tabla de scoring PO), por personeria y codmes. Replica el target de f2_mad (malo si condicion(dm)>90 o jud/castigo/refin/reestruct en la ventana alta+1..alta+12 en la entidad del alta). Devuelve rd y pd v2 en version conteo (cw) y ponderada por saldo (sw), mas numerador y denominador ponderados para poolear el factor sw = suma(saldo*bad) / suma(saldo*pd_v2). Con esto se decide PNN y PJJ sobre la MISMA base v2 y con peso de exposicion. READ-ONLY
WITH altas AS (
  SELECT cast(c.codmes AS int) AS cm, c.tip_doc, c.key_value, c.cod_instit_financiera AS ent,
         CASE WHEN c.flg_ppjj = 1 THEN 'PJJ' ELSE 'PNN' END AS per
  FROM disc_model_owner.ds_adm_bpe_bankbn_cal_202607 c
  WHERE c.entidad = 'IBK' AND c.flg_clean_calib <> 99 AND cast(c.codmes AS int) BETWEEN 202501 AND 202507
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
    max(CASE WHEN rcm BETWEEN w1 AND w12 AND rcm <= 202607 THEN bad ELSE 0 END) AS bad_207
  FROM j GROUP BY per, cm, tip_doc, key_value
),
sal AS (
  SELECT cast(codmes AS int) AS cm, tip_doc, key_value, max(cast(saldo_m0_ent AS double)) AS s0
  FROM disc_model_owner.ds_adm_bpe_bankbn_po
  WHERE marca_entidad = 'IBK'
  GROUP BY cast(codmes AS int), tip_doc, key_value
),
v2p AS (
  SELECT cast(codmes_alta AS int) AS cm, tip_doc, key_value, max(TRY_CAST(prob_modelo_cal_v2 AS double)) AS pd2
  FROM disc_model_owner.b46029_po_scoring_v1v2_202607
  GROUP BY cast(codmes_alta AS int), tip_doc, key_value
),
f AS (
  SELECT cl.per, cl.cm, cl.bad_207, s.s0, v.pd2
  FROM cli cl
  JOIN sal s ON s.cm = cl.cm AND s.tip_doc = cl.tip_doc AND s.key_value = cl.key_value
  JOIN v2p v ON v.cm = cl.cm AND v.tip_doc = cl.tip_doc AND v.key_value = cl.key_value
  WHERE s.s0 > 0 AND v.pd2 IS NOT NULL
)
SELECT per, cm AS codmes, count(*) AS n,
  round(sum(s0)/1000000.0, 2) AS saldo_mm,
  round(100.0 * avg(bad_207), 3) AS rd_cw,
  round(100.0 * sum(s0 * bad_207) / sum(s0), 3) AS rd_sw,
  round(100.0 * avg(pd2), 3) AS pd_v2_cw,
  round(100.0 * sum(s0 * pd2) / sum(s0), 3) AS pd_v2_sw,
  round(sum(s0 * bad_207), 2) AS num_sw,
  round(sum(s0 * pd2), 2) AS den_sw
FROM f
GROUP BY per, cm
ORDER BY per, cm
