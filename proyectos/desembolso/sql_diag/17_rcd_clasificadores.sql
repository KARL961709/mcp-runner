-- 17_rcd_clasificadores.sql | perfila los codigos de e_perm_aws.t_ifrs_rcddeta_rsk (un mes, p_codmes 202606) para ver desde que columna se identifican refinanciado, reestructurado, judicial, castigo y recuperaciones, y si nu_dias_vcdo sirve para la mora. Devuelve cardinalidad de cada codigo (bajo n_distinct = clasificador de estado), largo de la cuenta contable, maximo de dias vencidos y cuantas filas pasan 90 dias. Solo agregados, sin PII. READ-ONLY
WITH m AS (
  SELECT
    cast(count(*) AS bigint) AS n,
    cast(count(DISTINCT co_scta) AS bigint) AS d1,
    cast(count(DISTINCT co_prod) AS bigint) AS d2,
    cast(count(DISTINCT co_sub_prod) AS bigint) AS d3,
    cast(count(DISTINCT ti_cred) AS bigint) AS d4,
    cast(count(DISTINCT nu_cnta_cntb) AS bigint) AS d5,
    cast(count(DISTINCT co_rubr) AS bigint) AS d6,
    cast(count(DISTINCT tipo_cinta) AS bigint) AS d7,
    cast(count(DISTINCT co_apli) AS bigint) AS d8,
    cast(count(DISTINCT co_moneda) AS bigint) AS d9,
    cast(max(length(nu_cnta_cntb)) AS bigint) AS len_cnta,
    cast(max(try_cast(nu_dias_vcdo AS integer)) AS bigint) AS dias_max,
    cast(sum(CASE WHEN try_cast(nu_dias_vcdo AS integer) > 90 THEN 1 ELSE 0 END) AS bigint) AS n_mora90
  FROM e_perm_aws.t_ifrs_rcddeta_rsk WHERE p_codmes = '202606'
)
SELECT t.item, t.valor
FROM m
CROSS JOIN UNNEST(
  ARRAY['n_filas_mes','card_co_scta','card_co_prod','card_co_sub_prod','card_ti_cred','card_nu_cnta_cntb','len_max_nu_cnta_cntb','card_co_rubr','card_tipo_cinta','card_co_apli','card_co_moneda','nu_dias_vcdo_max','n_mora_gt90'],
  ARRAY[m.n, m.d1, m.d2, m.d3, m.d4, m.d5, m.len_cnta, m.d6, m.d7, m.d8, m.d9, m.dias_max, m.n_mora90]
) AS t(item, valor)
