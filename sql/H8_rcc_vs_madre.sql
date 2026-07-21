-- =====================================================================================
-- H8 | ¿Reconstruir las altas desde el RCC da el MISMO conjunto que la tabla madre?
--
-- Es la unica pregunta que queda para saber si la poblacion de calibracion es adecuada.
-- No hace falta portar las 13 CTEs de 01.AltasMonitoreoV4: basta reproducir el criterio
-- de alta y comparar conjuntos.
--
-- CRITERIO, verbatim de 01.AltasMonitoreoV4 (ojo la ASIMETRIA, no es un error):
--   * el DISPARO del alta usa tipo_credito 08/09/10 con saldo > 0 en el mes T
--   * la HISTORIA previa usa tipo_credito 1-10   (saldo_mo de morigbk_saldo_hist)
--   * ambas sobre cuenta 14.x con substr(4,1) IN ('1','3','4','5','6')  = vigente
--   * alta2 = sin saldo en T-1 NI en T-2
--   Ausencia de fila en el RCC = saldo cero (por eso LEFT JOIN + coalesce).
--
-- LO QUE NO PUEDO REPRODUCIR, y por eso el resultado puede diferir:
--   * el filtro `tag` ('RESTO DD NEGOCIO','DESCUENTOS',...) — no se si esa columna
--     existe en el RCC o viene de un join que no tengo
--   * `ent_honrada = 0`
--   * d_mdl_riesgos_disc.PO_PREVIA_AD_202305 — PO congelada de 2023 que usa el original
--
-- COMO SE LEE
--   solo_madre ~ 0 y solo_rcc ~ 0   -> la madre ES alta2 desde RCC. Partir del RCC
--                                      no aporta. Poblacion CONFIRMADA.
--   solo_rcc alto                   -> la madre filtra algo mas (PO previa / tags / monto)
--   solo_madre alto                 -> la madre usa una definicion MAS LAXA que alta2
--                                      (p.ej. alta1, o sin exigir historia limpia)
--   solapamiento bajo               -> son poblaciones distintas: hay que decidir cual
--
-- READ-ONLY. Meses T = 202603 y 202604 (el RCC se lee desde 202601 por el lookback).
-- =====================================================================================

WITH rccm AS (
  SELECT cast(codmes AS int) AS codmes,
         cast(tip_doc AS varchar) AS tip_doc, key_value,
         -- historia: tipo_credito 1-10, vigente
         sum(CASE WHEN cast(tipo_credito AS int) BETWEEN 1 AND 10
                   AND substr(cod_cuenta_rcc,1,2) = '14'
                   AND substr(cod_cuenta_rcc,4,1) IN ('1','3','4','5','6')
                  THEN saldo ELSE 0 END) AS s_hist,
         -- disparo: tipo_credito 8/9/10, vigente
         sum(CASE WHEN cast(tipo_credito AS int) IN (8,9,10)
                   AND substr(cod_cuenta_rcc,1,2) = '14'
                   AND substr(cod_cuenta_rcc,4,1) IN ('1','3','4','5','6')
                  THEN saldo ELSE 0 END) AS s_890
  FROM e_perm_aws.t_fact_report_rcc_rsk
  WHERE p_codmes BETWEEN '202601' AND '202604'
    AND codmes   BETWEEN '202601' AND '202604'
    AND cod_instit_financiera = '00002'
  GROUP BY 1,2,3
),
cand AS (
  SELECT * FROM rccm WHERE codmes IN (202603, 202604) AND s_890 > 0
),
alta_rcc AS (
  SELECT c.codmes, c.tip_doc, c.key_value
  FROM cand c
  LEFT JOIN rccm p1
    ON p1.tip_doc = c.tip_doc AND p1.key_value = c.key_value
   AND p1.codmes = cast(date_format(date_parse(cast(c.codmes AS varchar), '%Y%m')
                                    - interval '1' month, '%Y%m') AS int)
  LEFT JOIN rccm p2
    ON p2.tip_doc = c.tip_doc AND p2.key_value = c.key_value
   AND p2.codmes = cast(date_format(date_parse(cast(c.codmes AS varchar), '%Y%m')
                                    - interval '2' month, '%Y%m') AS int)
  WHERE coalesce(p1.s_hist, 0) = 0
    AND coalesce(p2.s_hist, 0) = 0
),
madre AS (
  SELECT cast(codmes AS int) AS codmes,
         cast(tip_doc AS varchar) AS tip_doc, key_value
  FROM disc_monitorian.t_dan_mrm_admbankbpe_altas_rep
  WHERE p_codmes BETWEEN '202603' AND '202604'
    AND cast(codmes AS int) IN (202603, 202604)
    AND cod_instit_financiera = '00002'
  GROUP BY 1,2,3
),
cmp AS (
  SELECT coalesce(a.codmes, m.codmes) AS codmes,
         CASE WHEN a.key_value IS NOT NULL AND m.key_value IS NOT NULL THEN 'ambos'
              WHEN a.key_value IS NOT NULL THEN 'solo_rcc'
              ELSE 'solo_madre' END AS lado
  FROM alta_rcc a
  FULL OUTER JOIN madre m
    ON m.codmes = a.codmes AND m.tip_doc = a.tip_doc AND m.key_value = a.key_value
)

SELECT cast(codmes AS varchar) AS codmes, lado, cast(count(*) AS varchar) AS n
FROM cmp GROUP BY 1,2

UNION ALL
SELECT 'TOTAL', lado, cast(count(*) AS varchar) FROM cmp GROUP BY lado

UNION ALL
-- contexto: cuantos candidatos habia antes de exigir historia limpia
SELECT 'CONTEXTO', 'candidatos RCC (saldo 8/9/10 > 0 en T)',
       cast(count(*) AS varchar) FROM cand
UNION ALL
SELECT 'CONTEXTO', 'de esos, alta2 (sin saldo en T-1 ni T-2)',
       cast(count(*) AS varchar) FROM alta_rcc
UNION ALL
SELECT 'CONTEXTO', 'filas IBK en la madre',
       cast(count(*) AS varchar) FROM madre
ORDER BY 1, 2
