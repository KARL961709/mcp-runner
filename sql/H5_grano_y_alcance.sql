-- =====================================================================================
-- H5 | ¿La tabla es de EVENTOS o foto de cartera? ¿y que alcance tiene el saldo?
--
-- LO YA ESTABLECIDO
--   H4: saldo_m1..m12 van HACIA ATRAS (100% de coincidencia, 12,925 pares).
--       => la cascada A-00..A-12 de H2/H3 SI mide historia previa, y esta bien.
--   H3: no hay NULLs (0 de 505,646).
--   H1: q1_altas_src copia la madre sin filtros (conteos exactos en 4 meses).
--
-- LA TENSION QUE QUEDA
--   Solo 12,925 pares consecutivos de 505,646 filas: los clientes NO se repiten mes a
--   mes, asi que la tabla parece de EVENTOS (una fila por alta). Pero el 92% tenia
--   saldo el mes anterior (A-00), que contradice que sean altas.
--
--   Reconciliacion posible: que saldo_m0..m12 midan un alcance MAS AMPLIO que el
--   producto que define el alta. En 01.AltasMonitoreoV4 el saldo venia filtrado a los
--   tags BPE ('RESTO DD NEGOCIO','DESCUENTOS','FACTORING','LC NO UTILIZADA','LC
--   DESCUENTO') y tipo_credito 08/09/10. Si en la madre el saldo es del cliente
--   completo, un alta BPE puede tener saldo previo en otros productos.
--
-- BLOQUE 1  ¿cuantas veces aparece cada cliente en 4 meses?
--           ~505k clientes distintos -> tabla de EVENTOS (una fila por alta)
--           ~126k clientes distintos -> foto de cartera (aparecen los 4 meses)
-- BLOQUE 2  ¿que hace la columna `rank`? q1 dice que viene con rank=1 aplicado.
-- BLOQUE 3  contraste del saldo de la madre contra el saldo BPE-ONLY del RCC,
--           mismo cliente y mes. Si difieren, el alcance es mas amplio y A-00 no
--           descalifica el alta.
-- READ-ONLY.
-- =====================================================================================

WITH m AS (
  SELECT cast(codmes AS int) AS codmes, tip_doc, key_value,
         cast(saldo_m0 AS double) AS s0, cast(rank AS bigint) AS rnk
  FROM disc_monitorian.t_dan_mrm_admbankbpe_altas_rep
  WHERE p_codmes BETWEEN '202601' AND '202604'
    AND cast(codmes AS int) BETWEEN 202601 AND 202604
),
rep AS (
  SELECT tip_doc, key_value, count(*) AS veces FROM m GROUP BY 1,2
),
-- saldo BPE-ONLY desde el RCC, con los filtros de 01.AltasMonitoreoV4
bpe AS (
  SELECT cast(codmes AS int) AS codmes, tip_doc, key_value,
         sum(CASE WHEN cast(tipo_credito AS int) IN (8,9,10)
                   AND substr(cod_cuenta_rcc,1,2) = '14'
                   AND substr(cod_cuenta_rcc,4,1) IN ('1','3','4','5','6')
                  THEN saldo ELSE 0 END) AS s_bpe,
         sum(saldo) AS s_todo
  FROM e_perm_aws.t_fact_report_rcc_rsk
  WHERE p_codmes BETWEEN '202601' AND '202604'
    AND codmes   BETWEEN '202601' AND '202604'
    AND cod_instit_financiera = '00002'
  GROUP BY 1,2,3
)

SELECT '1. REPETICION' AS bloque,
       'clientes que aparecen ' || cast(veces AS varchar) || ' vez/veces' AS detalle,
       cast(count(*) AS varchar) AS valor
FROM rep GROUP BY veces

UNION ALL
SELECT '1. REPETICION', 'clientes DISTINTOS en total', cast(count(*) AS varchar) FROM rep
UNION ALL
SELECT '1. REPETICION', 'filas en total', cast(count(*) AS varchar) FROM m

UNION ALL
SELECT '2. RANK', 'rank = ' || cast(rnk AS varchar), cast(count(*) AS varchar)
FROM m GROUP BY rnk

UNION ALL
-- ¿el saldo de la madre coincide con el saldo BPE del RCC, o con el total?
SELECT '3. ALCANCE', 'pares comparables (IBK)', cast(count(*) AS varchar)
FROM m JOIN bpe b ON b.codmes=m.codmes AND b.tip_doc=m.tip_doc AND b.key_value=m.key_value
UNION ALL
SELECT '3. ALCANCE', 'saldo_m0 ~ saldo BPE-only',
       cast(count_if(abs(m.s0 - b.s_bpe) <= 0.01*greatest(abs(b.s_bpe),1)) AS varchar)
FROM m JOIN bpe b ON b.codmes=m.codmes AND b.tip_doc=m.tip_doc AND b.key_value=m.key_value
UNION ALL
SELECT '3. ALCANCE', 'saldo_m0 ~ saldo TOTAL del cliente',
       cast(count_if(abs(m.s0 - b.s_todo) <= 0.01*greatest(abs(b.s_todo),1)) AS varchar)
FROM m JOIN bpe b ON b.codmes=m.codmes AND b.tip_doc=m.tip_doc AND b.key_value=m.key_value
ORDER BY 1,2
