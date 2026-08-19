-- =====================================================================================
-- h2 | COBERTURA por mes x subproducto de la calibrada 2606-2608. READ-ONLY.
--   Dice si es UNIVERSO (~millones/mes) o ALTAS (~miles), que meses trae, y los
--   niveles raw/pit. (Apuesta a p_codmes + subproducto + prob_modelo; si el nombre
--   real difiere, h1 lo revela y ajusto.)
-- =====================================================================================
SELECT cast(codmes AS varchar)                   AS mes,
       subproducto,
       count(*)                                  AS n,
       count(DISTINCT key_value)                 AS n_cli,
       round(100*avg(prob_modelo), 2)            AS pdraw,
       round(100*avg(prob_modelo_cal_ppfacil),2) AS pit_pf
FROM d_perm_aws.scr_vcadmbnk_hist_rsk_cal_2606_2608
GROUP BY cast(codmes AS varchar), subproducto
ORDER BY 1, 2
