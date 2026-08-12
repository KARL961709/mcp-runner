-- 13_kat_waterfall.sql | cobertura de filtros de la PO nueva partida por tipo de producto, para ver cuanto pesa el prestamo personal frente a la tarjeta
SELECT tip_prod,
       dsc_flg_malo_12m                                              AS motivo,
       count(*)                                                      AS n,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY tip_prod), 3) AS pct_en_prod,
       count(DISTINCT p_codmes)                                      AS meses
FROM d_perm_aws.ds_vc_mvp_no_bank_gdp_target_kat
GROUP BY tip_prod, dsc_flg_malo_12m
ORDER BY tip_prod, n DESC
