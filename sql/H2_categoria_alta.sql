-- =====================================================================================
-- H2 | ¿La tabla madre viene PRE-FILTRADA a alta2, o trae todo saldo_m0>0?
--
-- H1 mostro que la madre NO declara la definicion de alta (no hay columna alta2/6/12)
-- PERO trae saldo_m0 y saldo_m1..saldo_m12. Con eso la categoria A-00..A-12 de
-- 01.AltasMonitoreoV4.sql se reconstruye directo, sin tocar el RCC.
--
-- Cascada VERBATIM del original (de mayor a menor, gana la primera que cumple):
--     A-12  saldo_m1..saldo_m12 = 0     ... A-02  saldo_m1+saldo_m2 = 0
--     A-01  saldo_m1 = 0                    A-00  saldo continuo
--
-- LECTURA
--   Si TODO cae en A-02..A-12          -> la madre viene pre-filtrada a `alta2`.
--                                         La calibracion esta sobre alta2. Cerrado.
--   Si aparecen A-01 o A-00            -> la madre NO filtra, y nuestra altas_src
--                                         incluye NO-altas. La poblacion de
--                                         calibracion seria mas amplia que la documentada.
--   Si TODO cae en A-12                -> seria `alta12`, definicion mucho mas estricta
--                                         que la que asume el paquete.
--
-- Se abre por IBK vs resto: lo que importa para la calibracion es la columna IBK.
-- READ-ONLY.
-- =====================================================================================

WITH b AS (
  SELECT
    CASE WHEN cod_instit_financiera = '00002' THEN 'IBK' ELSE 'resto' END AS ent,
    cast(saldo_m0 AS double) AS s0,
    CASE
      WHEN cast(saldo_m0 AS double) IS NULL OR cast(saldo_m0 AS double) <= 0 THEN 'A-otro'
      WHEN cast(saldo_m1 AS double)+cast(saldo_m2 AS double)+cast(saldo_m3 AS double)
         + cast(saldo_m4 AS double)+cast(saldo_m5 AS double)+cast(saldo_m6 AS double)
         + cast(saldo_m7 AS double)+cast(saldo_m8 AS double)+cast(saldo_m9 AS double)
         + cast(saldo_m10 AS double)+cast(saldo_m11 AS double)+cast(saldo_m12 AS double) = 0 THEN 'A-12'
      WHEN cast(saldo_m1 AS double)+cast(saldo_m2 AS double)+cast(saldo_m3 AS double)
         + cast(saldo_m4 AS double)+cast(saldo_m5 AS double)+cast(saldo_m6 AS double)
         + cast(saldo_m7 AS double)+cast(saldo_m8 AS double)+cast(saldo_m9 AS double)
         + cast(saldo_m10 AS double)+cast(saldo_m11 AS double) = 0 THEN 'A-11'
      WHEN cast(saldo_m1 AS double)+cast(saldo_m2 AS double)+cast(saldo_m3 AS double)
         + cast(saldo_m4 AS double)+cast(saldo_m5 AS double)+cast(saldo_m6 AS double)
         + cast(saldo_m7 AS double)+cast(saldo_m8 AS double)+cast(saldo_m9 AS double)
         + cast(saldo_m10 AS double) = 0 THEN 'A-10'
      WHEN cast(saldo_m1 AS double)+cast(saldo_m2 AS double)+cast(saldo_m3 AS double)
         + cast(saldo_m4 AS double)+cast(saldo_m5 AS double)+cast(saldo_m6 AS double)
         + cast(saldo_m7 AS double)+cast(saldo_m8 AS double)+cast(saldo_m9 AS double) = 0 THEN 'A-09'
      WHEN cast(saldo_m1 AS double)+cast(saldo_m2 AS double)+cast(saldo_m3 AS double)
         + cast(saldo_m4 AS double)+cast(saldo_m5 AS double)+cast(saldo_m6 AS double)
         + cast(saldo_m7 AS double)+cast(saldo_m8 AS double) = 0 THEN 'A-08'
      WHEN cast(saldo_m1 AS double)+cast(saldo_m2 AS double)+cast(saldo_m3 AS double)
         + cast(saldo_m4 AS double)+cast(saldo_m5 AS double)+cast(saldo_m6 AS double)
         + cast(saldo_m7 AS double) = 0 THEN 'A-07'
      WHEN cast(saldo_m1 AS double)+cast(saldo_m2 AS double)+cast(saldo_m3 AS double)
         + cast(saldo_m4 AS double)+cast(saldo_m5 AS double)+cast(saldo_m6 AS double) = 0 THEN 'A-06'
      WHEN cast(saldo_m1 AS double)+cast(saldo_m2 AS double)+cast(saldo_m3 AS double)
         + cast(saldo_m4 AS double)+cast(saldo_m5 AS double) = 0 THEN 'A-05'
      WHEN cast(saldo_m1 AS double)+cast(saldo_m2 AS double)+cast(saldo_m3 AS double)
         + cast(saldo_m4 AS double) = 0 THEN 'A-04'
      WHEN cast(saldo_m1 AS double)+cast(saldo_m2 AS double)+cast(saldo_m3 AS double) = 0 THEN 'A-03'
      WHEN cast(saldo_m1 AS double)+cast(saldo_m2 AS double) = 0 THEN 'A-02'
      WHEN cast(saldo_m1 AS double) = 0 THEN 'A-01'
      ELSE 'A-00'
    END AS cat
  FROM disc_monitorian.t_dan_mrm_admbankbpe_altas_rep
  WHERE p_codmes BETWEEN '202601' AND '202604'
    AND cast(codmes AS int) BETWEEN 202601 AND 202604
)

SELECT cat AS categoria,
       count_if(ent = 'IBK')                                  AS n_ibk,
       count_if(ent = 'resto')                                AS n_resto,
       count(*)                                               AS n_total,
       round(100.0 * count_if(ent='IBK')
             / nullif(sum(count_if(ent='IBK')) OVER (), 0), 2) AS pct_ibk,
       CASE WHEN cat IN ('A-00','A-01','A-otro') THEN '<-- NO es alta2'
            ELSE 'dentro de alta2' END                         AS nota
FROM b
GROUP BY cat
ORDER BY cat
