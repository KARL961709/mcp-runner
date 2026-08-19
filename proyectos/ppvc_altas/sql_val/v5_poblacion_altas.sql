-- =====================================================================================
-- v5 | POBLACION de altas + fuente del raw, en un tiro. READ-ONLY.
--   Por codmes x subproducto sobre pp_vc_drivers_admbnk2 (el book de originacion):
--     - n_drv        = tamano de la poblacion (si P.FACIL ~ miles => son ALTAS;
--                      si millones => es el universo y falta el filtro de alta)
--     - n_match_hist = cuantas matchean el raw de scr_vcadmbnk_hist_rsk (mismo mes)
--     - prob_drivers vs prob_hist = si el raw embebido en drivers == el de hist_rsk
--       (decide si jalamos el score de hist_rsk como pediste, o del propio drivers)
--   Join por key_value + mes (sin tip_doc, para no perder match por formato de llave).
-- =====================================================================================
SELECT dr.codmes,
       dr.subproducto,
       count(*)                                       AS n_drv,
       count(v.key_value)                             AS n_match_hist,
       round(100.0 * count(v.key_value) / count(*), 1) AS match_pct,
       round(avg(dr.prob_modelo), 4)                  AS prob_drivers,
       round(avg(v.probabilidad), 4)                  AS prob_hist
FROM disc_model_owner.pp_vc_drivers_admbnk2 dr
LEFT JOIN d_perm_aws.scr_vcadmbnk_hist_rsk v
       ON v.key_value = dr.key_value
      AND cast(v.p_codmes AS varchar) = dr.codmes
WHERE dr.codmes IN ('202605', '202606')
GROUP BY dr.codmes, dr.subproducto
ORDER BY dr.codmes, dr.subproducto
