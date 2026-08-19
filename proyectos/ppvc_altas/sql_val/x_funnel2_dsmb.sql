-- x_funnel2 | Verifica el cruce t_dsmb_pp_7339 -> key_value -> universo calibrado. READ-ONLY.
--   n_altas = P.FACIL jun/jul en t_dsmb | n_keys = tras ca_cod_unic->key_value (ctaibk)
--   n_join_key = matchean cal por key_value | n_join_keymes = por key_value + codmes
WITH altas AS (
  SELECT DISTINCT ca_periodo AS codmes,
         CASE WHEN length(ca_cod_unic) >= 10 THEN ca_cod_unic ELSE lpad(ca_cod_unic, 10, '0') END AS cod_cuc
  FROM d_perm_aws.t_dsmb_pp_7339
  WHERE ca_periodo IN ('202606', '202607') AND sub_prod = '5.P FACIL'
),
k AS (
  SELECT DISTINCT a.codmes, b.key_value
  FROM altas a JOIN e_perm_aws.t_mst_ctaibk_rsk b ON b.cod_cuc = a.cod_cuc
  WHERE b.key_value IS NOT NULL
)
SELECT
  (SELECT count(*) FROM altas) AS n_altas,
  (SELECT count(*) FROM k)     AS n_keys,
  (SELECT count(*) FROM k JOIN d_perm_aws.scr_vcadmbnk_hist_rsk_cal_2606_2608 c
       ON c.key_value = k.key_value) AS n_join_key,
  (SELECT count(*) FROM k JOIN d_perm_aws.scr_vcadmbnk_hist_rsk_cal_2606_2608 c
       ON c.key_value = k.key_value AND cast(c.codmes AS varchar) = k.codmes) AS n_join_keymes
