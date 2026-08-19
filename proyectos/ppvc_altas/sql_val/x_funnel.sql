-- =====================================================================================
-- x_funnel | Localiza donde se rompe el cruce altas->scores. READ-ONLY. 1 fila, 4 conteos.
--   n_mon        = altas P.FACIL en la madre raw (jun/jul)        -> 0 = fuente/subproducto/acceso
--   n_keys       = tras mapear cif_key -> key_value (t_mst_ctaibk)-> 0 = mapeo de llave
--   n_join_key   = matchean la tabla calibrada por key_value      -> 0 = formato de key_value distinto
--   n_join_keymes= matchean por key_value + codmes                -> < anterior = tema de mes/rezago
-- (sin swap/cima aqui: aislo el pipeline; esos solo restan mas)
-- =====================================================================================
WITH mon AS (
  SELECT cast(codmes_desembolso AS varchar) AS codmes,
         CASE WHEN length(cif_key) >= 10 THEN cif_key ELSE lpad(cif_key, 10, '0') END AS cod_cuc
  FROM disc_monitorian.t_mrm_mongest_altas_pp_marcas
  WHERE cast(codmes_desembolso AS varchar) IN ('202606', '202607')
    AND upper(subproducto) LIKE '%FACIL%'
),
k AS (
  SELECT DISTINCT m.codmes, b.key_value
  FROM mon m
  JOIN e_perm_aws.t_mst_ctaibk_rsk b ON b.cod_cuc = m.cod_cuc
  WHERE b.key_value IS NOT NULL
)
SELECT
  (SELECT count(*) FROM mon) AS n_mon,
  (SELECT count(*) FROM k)   AS n_keys,
  (SELECT count(*) FROM k JOIN d_perm_aws.scr_vcadmbnk_hist_rsk_cal_2606_2608 c
       ON c.key_value = k.key_value) AS n_join_key,
  (SELECT count(*) FROM k JOIN d_perm_aws.scr_vcadmbnk_hist_rsk_cal_2606_2608 c
       ON c.key_value = k.key_value AND cast(c.codmes AS varchar) = k.codmes) AS n_join_keymes
