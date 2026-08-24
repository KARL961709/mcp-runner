-- 132_ibk_rd_horizontes_saldo_202607.sql | RD por horizonte h6..h12 PONDERADA POR saldo (exposicion IBK) para proyectar el factor v2 saldo-weighted en cohortes inmaduras (202508-10). Re-madura con RCC cerrado a 202607: malo_h = 1 si en la ventana alta+1..alta+h (y rcm<=202607) hay condicion(dm)>90 o jud/castigo/refin/reestruct en la entidad del alta. Devuelve por personeria y codmes: Sum(saldo*pd_v2) y Sum(saldo*malo_h) para h=6..12, mas Sum(saldo) y n. Con esto: dev_sw(h->12)=Sum_maduro(sw12)/Sum_maduro(sw_h) y factor con proy = (Sum_maduro sw12 + Sum_inmaduro sw_frontera*dev_sw)/Sum(saldo*pd_v2). Cohortes 202501-10; con RCC 202607, 202507 cierra h12, 202508 llega h11, 202509 h10, 202510 h9. READ-ONLY
WITH altas AS (
  SELECT cast(c.codmes AS int) AS cm, c.tip_doc, c.key_value, c.cod_instit_financiera AS ent,
         CASE WHEN c.flg_ppjj = 1 THEN 'PJJ' ELSE 'PNN' END AS per
  FROM disc_model_owner.ds_adm_bpe_bankbn_cal_202607 c
  WHERE c.entidad = 'IBK' AND c.flg_clean_calib <> 99 AND cast(c.codmes AS int) BETWEEN 202501 AND 202510
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
    cast(date_format(date_parse(cast(a.cm AS varchar),'%Y%m') + interval '6'  month,'%Y%m') AS int) AS w6,
    cast(date_format(date_parse(cast(a.cm AS varchar),'%Y%m') + interval '7'  month,'%Y%m') AS int) AS w7,
    cast(date_format(date_parse(cast(a.cm AS varchar),'%Y%m') + interval '8'  month,'%Y%m') AS int) AS w8,
    cast(date_format(date_parse(cast(a.cm AS varchar),'%Y%m') + interval '9'  month,'%Y%m') AS int) AS w9,
    cast(date_format(date_parse(cast(a.cm AS varchar),'%Y%m') + interval '10' month,'%Y%m') AS int) AS w10,
    cast(date_format(date_parse(cast(a.cm AS varchar),'%Y%m') + interval '11' month,'%Y%m') AS int) AS w11,
    cast(date_format(date_parse(cast(a.cm AS varchar),'%Y%m') + interval '12' month,'%Y%m') AS int) AS w12,
    d.rcm,
    CASE WHEN d.dm > 90 OR d.jud = 1 OR d.cst = 1 OR d.ref = 1 OR d.ree = 1 THEN 1 ELSE 0 END AS bad
  FROM altas a
  LEFT JOIN dr d ON d.tip_doc = a.tip_doc AND d.key_value = a.key_value AND d.ent = a.ent
),
cli AS (
  SELECT per, cm, tip_doc, key_value,
    max(CASE WHEN rcm BETWEEN w1 AND w6  AND rcm <= 202607 THEN bad ELSE 0 END) AS b06,
    max(CASE WHEN rcm BETWEEN w1 AND w7  AND rcm <= 202607 THEN bad ELSE 0 END) AS b07,
    max(CASE WHEN rcm BETWEEN w1 AND w8  AND rcm <= 202607 THEN bad ELSE 0 END) AS b08,
    max(CASE WHEN rcm BETWEEN w1 AND w9  AND rcm <= 202607 THEN bad ELSE 0 END) AS b09,
    max(CASE WHEN rcm BETWEEN w1 AND w10 AND rcm <= 202607 THEN bad ELSE 0 END) AS b10,
    max(CASE WHEN rcm BETWEEN w1 AND w11 AND rcm <= 202607 THEN bad ELSE 0 END) AS b11,
    max(CASE WHEN rcm BETWEEN w1 AND w12 AND rcm <= 202607 THEN bad ELSE 0 END) AS b12
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
  SELECT cl.per, cl.cm, cl.b06, cl.b07, cl.b08, cl.b09, cl.b10, cl.b11, cl.b12, s.s0, v.pd2
  FROM cli cl
  JOIN sal s ON s.cm = cl.cm AND s.tip_doc = cl.tip_doc AND s.key_value = cl.key_value
  JOIN v2p v ON v.cm = cl.cm AND v.tip_doc = cl.tip_doc AND v.key_value = cl.key_value
  WHERE s.s0 > 0 AND v.pd2 IS NOT NULL
)
SELECT per, cm AS codmes, count(*) AS n,
  round(sum(s0)/1000000.0, 2) AS saldo_mm,
  round(sum(s0 * pd2), 2) AS den_pdv2,
  round(sum(s0 * b06), 2) AS sw06,
  round(sum(s0 * b07), 2) AS sw07,
  round(sum(s0 * b08), 2) AS sw08,
  round(sum(s0 * b09), 2) AS sw09,
  round(sum(s0 * b10), 2) AS sw10,
  round(sum(s0 * b11), 2) AS sw11,
  round(sum(s0 * b12), 2) AS sw12
FROM f
GROUP BY per, cm
ORDER BY per, cm
