-- =====================================================================================
-- H7 | ¿saldo_m0 es del cliente en TODO EL SISTEMA?
--
-- H6 descarto las tres opciones dentro de IBK. Lo decisivo fueron las medianas:
--     saldo_m0  426,182      s_todo (IBK, todos los productos)  162,479
-- saldo_m0 es 2.6x mas grande que TODA la deuda del cliente en Interbank, asi que
-- no puede ser un saldo de IBK.
--
-- HIPOTESIS: cod_instit_financiera marca DONDE ocurrio el alta, pero saldo_m0..m12
-- siguen la exposicion del cliente en TODAS las entidades.
--
-- Si se confirma, la cascada A-00..A-12 de H2/H3 no mide lo que yo creia: mide
-- "¿tenia deuda en algun lado el mes pasado?" en vez de "¿tenia un BPE en IBK?".
-- El 92% en A-00 seria artefacto y la poblacion de calibracion estaria bien.
--
-- Se prueban cuatro alcances, todos SIN filtrar entidad:
--   d. todo el saldo del cliente, todas las entidades, todos los productos
--   e. idem pero solo vigente 14.x [1,3,4,5,6]
--   f. idem pero solo tipo_credito 1-10 (perimetro de la definicion original)
--   g. solo TOP4 (00001, 00002, 00004, 00006)
-- READ-ONLY.
-- =====================================================================================

WITH m AS (
  SELECT cast(codmes AS int) AS codmes,
         cast(tip_doc AS varchar) AS tip_doc, key_value,
         cast(saldo_m0 AS double) AS s0
  FROM disc_monitorian.t_dan_mrm_admbankbpe_altas_rep
  WHERE p_codmes BETWEEN '202601' AND '202604'
    AND cast(codmes AS int) BETWEEN 202601 AND 202604
    AND cod_instit_financiera = '00002'
),
sis AS (
  SELECT cast(codmes AS int) AS codmes,
         cast(tip_doc AS varchar) AS tip_doc, key_value,
         sum(saldo) AS s_sist,
         sum(CASE WHEN substr(cod_cuenta_rcc,1,2) = '14'
                   AND substr(cod_cuenta_rcc,4,1) IN ('1','3','4','5','6')
                  THEN saldo ELSE 0 END) AS s_sist_vig,
         sum(CASE WHEN cast(tipo_credito AS int) BETWEEN 1 AND 10
                   AND substr(cod_cuenta_rcc,1,2) = '14'
                   AND substr(cod_cuenta_rcc,4,1) IN ('1','3','4','5','6')
                  THEN saldo ELSE 0 END) AS s_sist_110,
         sum(CASE WHEN cod_instit_financiera IN ('00001','00002','00004','00006')
                  THEN saldo ELSE 0 END) AS s_top4
  FROM e_perm_aws.t_fact_report_rcc_rsk
  WHERE p_codmes BETWEEN '202601' AND '202604'
    AND codmes   BETWEEN '202601' AND '202604'
  GROUP BY 1,2,3
),
j AS (
  SELECT m.s0, s.s_sist, s.s_sist_vig, s.s_sist_110, s.s_top4
  FROM m JOIN sis s
    ON s.codmes = m.codmes AND s.tip_doc = m.tip_doc AND s.key_value = m.key_value
)

SELECT 'pares comparables' AS detalle, cast(count(*) AS varchar) AS valor FROM j
UNION ALL SELECT 'd. saldo_m0 ~ sistema, todo',
       cast(count_if(abs(s0 - s_sist)     <= 0.01*greatest(abs(s_sist),1))     AS varchar) FROM j
UNION ALL SELECT 'e. saldo_m0 ~ sistema, vigente 14.x',
       cast(count_if(abs(s0 - s_sist_vig) <= 0.01*greatest(abs(s_sist_vig),1)) AS varchar) FROM j
UNION ALL SELECT 'f. saldo_m0 ~ sistema, vigente + tipo 1-10',
       cast(count_if(abs(s0 - s_sist_110) <= 0.01*greatest(abs(s_sist_110),1)) AS varchar) FROM j
UNION ALL SELECT 'g. saldo_m0 ~ solo TOP4',
       cast(count_if(abs(s0 - s_top4)     <= 0.01*greatest(abs(s_top4),1))     AS varchar) FROM j
UNION ALL SELECT 'mediana saldo_m0',
       cast(cast(approx_percentile(s0,0.5)         AS bigint) AS varchar) FROM j
UNION ALL SELECT 'mediana sistema todo',
       cast(cast(approx_percentile(s_sist,0.5)     AS bigint) AS varchar) FROM j
UNION ALL SELECT 'mediana sistema vigente',
       cast(cast(approx_percentile(s_sist_vig,0.5) AS bigint) AS varchar) FROM j
UNION ALL SELECT 'mediana sistema vig + 1-10',
       cast(cast(approx_percentile(s_sist_110,0.5) AS bigint) AS varchar) FROM j
UNION ALL SELECT 'mediana TOP4',
       cast(cast(approx_percentile(s_top4,0.5)     AS bigint) AS varchar) FROM j
ORDER BY 1
