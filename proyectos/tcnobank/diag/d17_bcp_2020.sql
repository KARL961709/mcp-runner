-- ============================================================================
-- D17. QUE SON LAS ALTAS SIN LINEA DE BCP EN 2020 Y SI REF Y REE ESTAN CRUZADOS
--   scan: cal U e_perm_aws.t_fact_report_rcc_rsk [201902,202212], entidad 00001
--   ancla: 86_qa falla en BCP 2020 con 48.7 por ciento sin linea contra 1.0 en 2019.
--          Si el digito 3 o 4 de la subcuenta 14 se enciende ahi, son reestructurados y
--          el filtro correcto ya existe. Y f_ree_ori dispara 1 vez en 13.5M, que es
--          absurdo: la misma query mide si el mapeo de digitos esta cruzado
-- ============================================================================
WITH b AS (
    SELECT codmes_mrm, tip_doc, id_value, entidad,
           max(f_sin_linea) AS f_sin_linea,
           max(target_12m)  AS target_12m
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal
    WHERE entidad = '00001' AND codmes_mrm BETWEEN '201902' AND '202212'
    GROUP BY codmes_mrm, tip_doc, id_value, entidad
),
x AS (
    SELECT substr(b.codmes_mrm, 1, 4)                                                   AS anio,
           b.f_sin_linea,
           b.target_12m,
           max(CASE WHEN substr(a.cod_cuenta_rcc,1,2) = '14'
                     AND substr(a.cod_cuenta_rcc,4,1) = '1' THEN 1 ELSE 0 END)          AS d1_vigente,
           max(CASE WHEN substr(a.cod_cuenta_rcc,1,2) = '14'
                     AND substr(a.cod_cuenta_rcc,4,1) = '3' THEN 1 ELSE 0 END)          AS d3,
           max(CASE WHEN substr(a.cod_cuenta_rcc,1,2) = '14'
                     AND substr(a.cod_cuenta_rcc,4,1) = '4' THEN 1 ELSE 0 END)          AS d4,
           max(CASE WHEN substr(a.cod_cuenta_rcc,1,2) = '14'
                     AND substr(a.cod_cuenta_rcc,4,1) = '5' THEN 1 ELSE 0 END)          AS d5_vencido,
           max(CASE WHEN substr(a.cod_cuenta_rcc,1,2) = '14'
                     AND substr(a.cod_cuenta_rcc,4,1) = '6' THEN 1 ELSE 0 END)          AS d6_judicial,
           max(CASE WHEN substr(a.cod_cuenta_rcc,1,2) = '81'
                     AND substr(a.cod_cuenta_rcc,4,3) IN ('302','925') THEN 1 ELSE 0 END) AS castigo,
           sum(CASE WHEN substr(a.cod_cuenta_rcc,1,2) = '14' THEN a.saldo ELSE 0 END)   AS sld_usado
    FROM b
    INNER JOIN e_perm_aws.t_fact_report_rcc_rsk a
           ON a.tip_doc = b.tip_doc AND a.key_value = b.id_value
          AND ltrim(rtrim(a.cod_instit_financiera)) = b.entidad
          AND a.p_codmes = b.codmes_mrm
    WHERE a.p_codmes BETWEEN '201902' AND '202212'
    GROUP BY substr(b.codmes_mrm, 1, 4), b.codmes_mrm, b.tip_doc, b.id_value,
             b.f_sin_linea, b.target_12m
)
SELECT anio,
       f_sin_linea,
       count(*)                                                                         AS n,
       round(100.0 * avg(CAST(d1_vigente  AS DOUBLE)), 3)                               AS pct_d1_vigente,
       round(100.0 * avg(CAST(d3          AS DOUBLE)), 3)                               AS pct_d3,
       round(100.0 * avg(CAST(d4          AS DOUBLE)), 3)                               AS pct_d4,
       round(100.0 * avg(CAST(d5_vencido  AS DOUBLE)), 3)                               AS pct_d5_vencido,
       round(100.0 * avg(CAST(d6_judicial AS DOUBLE)), 3)                               AS pct_d6_judicial,
       round(100.0 * avg(CAST(castigo     AS DOUBLE)), 3)                               AS pct_castigo,
       round(avg(sld_usado), 0)                                                          AS sld_usado_medio,
       round(100.0 * avg(CAST(target_12m AS DOUBLE)), 4)                                AS rd_12m
FROM x
GROUP BY anio, f_sin_linea
ORDER BY anio, f_sin_linea
