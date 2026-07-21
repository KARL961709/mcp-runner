-- =====================================================================================
-- H4 | ¿saldo_m1..saldo_m12 van HACIA ATRAS o HACIA ADELANTE?
--
-- De esto depende todo. Si van hacia atras, la cascada A-00..A-12 de H2/H3 mide la
-- historia previa y el 92% en A-00 significaria que la tabla trae clientes continuos
-- (no altas). Si van hacia adelante, esa misma cascada no mide nada: el 92% con
-- saldo_m1>0 solo diria que un mes despues del desembolso todavia hay deuda.
--
-- H3 descarto la hipotesis de los NULL (0 de 505,646 en todas las columnas), asi que
-- el numero esta bien calculado — lo que esta en duda es QUE representa.
--
-- TEST. Se toma el mismo cliente en meses consecutivos y se compara:
--     saldo_m1 en el mes T   contra   saldo_m0 en el mes T-1      -> si coincide: ATRAS
--     saldo_m1 en el mes T   contra   saldo_m0 en el mes T+1      -> si coincide: ADELANTE
-- Gana la que empareje en la gran mayoria de los casos. No hay ambiguedad posible.
--
-- Se compara con tolerancia relativa (los decimales pueden diferir por redondeo).
-- READ-ONLY.
-- =====================================================================================

WITH t AS (
  SELECT cast(codmes AS int) AS codmes, tip_doc, key_value,
         cast(saldo_m0 AS double) AS s0,
         cast(saldo_m1 AS double) AS s1
  FROM disc_monitorian.t_dan_mrm_admbankbpe_altas_rep
  WHERE p_codmes BETWEEN '202601' AND '202604'
    AND cast(codmes AS int) BETWEEN 202601 AND 202604
),
prev AS (   -- s1 del mes T  vs  s0 del mes T-1   (hipotesis ATRAS)
  SELECT a.codmes, a.tip_doc, a.key_value, a.s1, b.s0 AS s0_ant
  FROM t a
  JOIN t b ON b.tip_doc = a.tip_doc AND b.key_value = a.key_value
          AND b.codmes = cast(date_format(date_parse(cast(a.codmes AS varchar), '%Y%m')
                                          - interval '1' month, '%Y%m') AS int)
),
post AS (   -- s1 del mes T  vs  s0 del mes T+1   (hipotesis ADELANTE)
  SELECT a.codmes, a.tip_doc, a.key_value, a.s1, b.s0 AS s0_sig
  FROM t a
  JOIN t b ON b.tip_doc = a.tip_doc AND b.key_value = a.key_value
          AND b.codmes = cast(date_format(date_parse(cast(a.codmes AS varchar), '%Y%m')
                                          + interval '1' month, '%Y%m') AS int)
)

SELECT 'A. HIPOTESIS ATRAS  (s1[T] = s0[T-1])' AS hipotesis,
       cast(count(*) AS varchar)                                        AS pares,
       cast(count_if(abs(s1 - s0_ant) <= 0.01 * greatest(abs(s0_ant), 1)) AS varchar) AS coinciden,
       cast(round(100.0 * count_if(abs(s1 - s0_ant) <= 0.01 * greatest(abs(s0_ant), 1))
                  / nullif(count(*), 0), 2) AS varchar) || ' %'         AS pct
FROM prev

UNION ALL

SELECT 'B. HIPOTESIS ADELANTE  (s1[T] = s0[T+1])',
       cast(count(*) AS varchar),
       cast(count_if(abs(s1 - s0_sig) <= 0.01 * greatest(abs(s0_sig), 1)) AS varchar),
       cast(round(100.0 * count_if(abs(s1 - s0_sig) <= 0.01 * greatest(abs(s0_sig), 1))
                  / nullif(count(*), 0), 2) AS varchar) || ' %'
FROM post

UNION ALL

-- control: cuantos s1 son cero, para dimensionar
SELECT 'C. CONTROL  s1 = 0', cast(count(*) AS varchar),
       cast(count_if(s1 = 0) AS varchar),
       cast(round(100.0 * count_if(s1 = 0) / nullif(count(*), 0), 2) AS varchar) || ' %'
FROM t
ORDER BY 1
