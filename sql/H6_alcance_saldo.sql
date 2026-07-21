-- =====================================================================================
-- H6 | CORRIGE el bloque 3 de H5 — ¿que mide saldo_m0 de la tabla madre?
--
-- DOS BUGS DE H5, ambos invalidaban la comparacion:
--   1. No filtre la madre a IBK: cruzaba altas de CUALQUIER entidad contra el RCC de
--      Interbank. Se noto en que salieron 23,552 pares cuando la madre solo tiene
--      2,685 filas IBK.
--   2. Use tipo_credito IN (8,9,10) para el saldo. En 01.AltasMonitoreoV4 el saldo va
--      con BETWEEN 1 AND 10; el 08/09/10 aplica solo a la CONDICION de alta.
--
-- Aqui se cruza entidad con entidad y se prueban tres definiciones de saldo.
--
-- LECTURA
--   Si saldo_m0 ~ 'BPE (14.x vigente, tipo 1-10)' en la gran mayoria
--        -> el saldo es del producto, y A-00 (92%) significa que la tabla trae
--           clientes con saldo BPE continuo. La poblacion de calibracion incluiria
--           gente que NO es alta.
--   Si saldo_m0 ~ 'TODO el saldo del cliente en la entidad'
--        -> el alcance es mas amplio: un alta BPE puede tener saldo previo en otros
--           productos, y A-00 no descalifica nada. Todo correcto.
--   Si no coincide con ninguna -> el saldo viene de otra fuente y hay que preguntar.
-- READ-ONLY.
-- =====================================================================================

WITH m AS (
  SELECT cast(codmes AS int) AS codmes,
         cast(tip_doc AS varchar) AS tip_doc, key_value,
         cast(cod_instit_financiera AS varchar) AS ent,
         cast(saldo_m0 AS double) AS s0
  FROM disc_monitorian.t_dan_mrm_admbankbpe_altas_rep
  WHERE p_codmes BETWEEN '202601' AND '202604'
    AND cast(codmes AS int) BETWEEN 202601 AND 202604
    AND cod_instit_financiera = '00002'          -- <<< IBK, el filtro que faltaba
),
r AS (
  SELECT cast(codmes AS int) AS codmes,
         cast(tip_doc AS varchar) AS tip_doc, key_value,
         cast(cod_instit_financiera AS varchar) AS ent,
         -- (a) BPE: vigente 14.x [1,3,4,5,6], tipo_credito 1-10  (definicion original)
         sum(CASE WHEN cast(tipo_credito AS int) BETWEEN 1 AND 10
                   AND substr(cod_cuenta_rcc,1,2) = '14'
                   AND substr(cod_cuenta_rcc,4,1) IN ('1','3','4','5','6')
                  THEN saldo ELSE 0 END) AS s_bpe,
         -- (b) solo tipo_credito 8/9/10 (el del criterio de alta)
         sum(CASE WHEN cast(tipo_credito AS int) IN (8,9,10)
                   AND substr(cod_cuenta_rcc,1,2) = '14'
                   AND substr(cod_cuenta_rcc,4,1) IN ('1','3','4','5','6')
                  THEN saldo ELSE 0 END) AS s_890,
         -- (c) todo el saldo del cliente en esa entidad
         sum(saldo) AS s_todo
  FROM e_perm_aws.t_fact_report_rcc_rsk
  WHERE p_codmes BETWEEN '202601' AND '202604'
    AND codmes   BETWEEN '202601' AND '202604'
    AND cod_instit_financiera = '00002'
  GROUP BY 1,2,3,4
),
j AS (
  SELECT m.s0, r.s_bpe, r.s_890, r.s_todo
  FROM m JOIN r
    ON r.codmes = m.codmes AND r.tip_doc = m.tip_doc
   AND r.key_value = m.key_value AND r.ent = m.ent
)

SELECT 'filas IBK en la madre' AS detalle, cast(count(*) AS varchar) AS valor FROM m
UNION ALL SELECT 'pares comparables (deben ser <= filas IBK)', cast(count(*) AS varchar) FROM j
UNION ALL SELECT 'a. saldo_m0 ~ BPE vigente, tipo 1-10',
       cast(count_if(abs(s0 - s_bpe)  <= 0.01*greatest(abs(s_bpe),1)) AS varchar) FROM j
UNION ALL SELECT 'b. saldo_m0 ~ BPE vigente, tipo 8-9-10',
       cast(count_if(abs(s0 - s_890)  <= 0.01*greatest(abs(s_890),1)) AS varchar) FROM j
UNION ALL SELECT 'c. saldo_m0 ~ TODO el saldo en la entidad',
       cast(count_if(abs(s0 - s_todo) <= 0.01*greatest(abs(s_todo),1)) AS varchar) FROM j
UNION ALL SELECT 'medianas: saldo_m0',    cast(cast(approx_percentile(s0,0.5)     AS bigint) AS varchar) FROM j
UNION ALL SELECT 'medianas: s_bpe',       cast(cast(approx_percentile(s_bpe,0.5)  AS bigint) AS varchar) FROM j
UNION ALL SELECT 'medianas: s_890',       cast(cast(approx_percentile(s_890,0.5)  AS bigint) AS varchar) FROM j
UNION ALL SELECT 'medianas: s_todo',      cast(cast(approx_percentile(s_todo,0.5) AS bigint) AS varchar) FROM j
ORDER BY 1
