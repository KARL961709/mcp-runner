-- qa_04_comparable.sql | CORRIGE la comparacion de qa_02 y qa_03. Ahi rd12_pct sale de las
-- maduras y pd_raw_medio_pct de las que tienen score: son POBLACIONES DISTINTAS y las dos
-- columnas no se pueden restar. Aca todo se mide sobre la misma poblacion (madura Y con score),
-- que es la unica sobre la que se puede calibrar, y se reporta cuanto se pierde al exigirla.
-- ic95 = mitad del intervalo normal de la RD, en pp: dice si la brecha aguanta el n. READ-ONLY
SELECT desc_producto,
  count(*)                                                                              AS n,
  sum(CASE WHEN meses_madurez = 12 AND sin_pd = 0 THEN 1 ELSE 0 END)                    AS n_calibrable,
  round(100.0 * sum(CASE WHEN meses_madurez = 12 AND sin_pd = 0 THEN 1 ELSE 0 END)
        / count(*), 1)                                                                  AS pct_calibrable,
  round(100.0 * avg(CASE WHEN meses_madurez = 12 AND sin_pd = 0
                         THEN cast(target_12m AS double) END), 3)                       AS rd12_pct,
  round(100.0 * avg(CASE WHEN meses_madurez = 12 AND sin_pd = 0 THEN pd_raw END), 3)    AS pd_raw_pct,
  round(10000.0 * (avg(CASE WHEN meses_madurez = 12 AND sin_pd = 0 THEN pd_raw END)
                 - avg(CASE WHEN meses_madurez = 12 AND sin_pd = 0
                            THEN cast(target_12m AS double) END)), 1)                   AS gap_bps,
  round(avg(CASE WHEN meses_madurez = 12 AND sin_pd = 0 THEN cast(target_12m AS double) END)
        / nullif(avg(CASE WHEN meses_madurez = 12 AND sin_pd = 0 THEN pd_raw END), 0), 3) AS factor_rd_pd,
  round(100.0 * 1.96 * sqrt(
        avg(CASE WHEN meses_madurez = 12 AND sin_pd = 0 THEN cast(target_12m AS double) END)
        * (1 - avg(CASE WHEN meses_madurez = 12 AND sin_pd = 0 THEN cast(target_12m AS double) END))
        / nullif(sum(CASE WHEN meses_madurez = 12 AND sin_pd = 0 THEN 1 ELSE 0 END), 0)), 3) AS ic95_pp
FROM disc_model_owner.b46029_desemb_cal_202609
GROUP BY desc_producto
ORDER BY n DESC
