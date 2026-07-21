-- =====================================================================================
-- QA_impulsa_2024.sql | ¿el anomalo 2024 se explica por Impulsa / Reactiva?
--
-- EL HECHO A EXPLICAR
--   Sobre altas SIN impulsa ni reactiva:
--     anio      n       RD      pd_raw
--     2022    3,031   12.11%   10.21%
--     2023    4,516   13.80%   10.70%
--     2024    1,677    4.41%   10.49%   <-- mismo pd_raw, RD a un tercio
--     2025    2,373    4.30%    5.57%
--   El pd_raw de 2024 es igual al de 2022-2023, pero incumple a un tercio. Y el
--   volumen cae 63% (376/mes en 2023 -> 140/mes en 2024).
--   Para cuadrarlo haria falta f_t = +7.28 contra el techo de +2.02: no es ciclo.
--
-- LA HIPOTESIS QUE HAY QUE PROBAR
--   Que Impulsa absorbio el grueso de la originacion de 2024 y lo que quedo fuera
--   del programa es un remanente pequenio y no representativo.
--   La afirme sin probarla: mis parquets ya excluyen a los Impulsa, asi que desde
--   local no puedo ver el otro lado. Esto lo mide.
--
-- COMO SE LEE
--   Si en 2024 el grupo con_programa es GRANDE  -> confirma que absorbio la originacion
--   Si su RD es MAYOR que la del resto          -> confirma que se llevo a los peores,
--                                                  dejando un residuo sano que el
--                                                  scorecard no distingue
--   Si su RD es MENOR o similar                 -> la hipotesis NO se sostiene y hay
--                                                  que buscar otra explicacion
--
-- Ventana 202207-202505 (12m de maduracion cerrada). ~8 filas.
-- READ-ONLY.
-- =====================================================================================

SELECT
  cast(cast(codmes AS int) / 100 AS varchar)                        AS anio,
  CASE WHEN coalesce(flg_impulsa,0) = 1
         OR coalesce(flg_reactiva_puro,0) = 1
       THEN 'con_programa' ELSE 'sin_programa' END                  AS grupo,
  count(*)                                                          AS n,
  sum(target_12m)                                                   AS defaults,
  round(100.0 * avg(cast(target_12m AS double)), 2)                 AS rd_pct,
  round(100.0 * count(*)
        / sum(count(*)) OVER (PARTITION BY cast(cast(codmes AS int) / 100 AS varchar)), 1)
                                                                    AS pct_del_anio,
  sum(coalesce(flg_impulsa,0))                                      AS n_impulsa,
  sum(coalesce(flg_reactiva_puro,0))                                AS n_reactiva
FROM disc_model_owner.bnbpe_ibk_calib_src
WHERE flg_ibk = 1
  AND top4_entidad = 'TOP4'
  AND cast(codmes AS int) BETWEEN 202207 AND 202505
GROUP BY 1, 2
ORDER BY 1, 2
