-- 124_diag_saldo_ibk.sql | por que el ticket 50k deja tan pocos IBK. Compara max_saldo_ent (pico consolidado 12m PRE-alta, con WHERE max_saldo>0 que bota clientes nuevos) contra saldo_m0_ent (consolidado en el mes del alta). Descompone total IBK calib, cuantos matchean _po y cuantos pasan cada umbral, por mes reciente y bucket historico. READ-ONLY
WITH cal AS (
  SELECT cast(codmes AS int) AS codmes, tip_doc, key_value
  FROM disc_model_owner.ds_adm_bpe_bankbn_cal_202607
  WHERE entidad = 'IBK' AND pd_raw IS NOT NULL AND fhat IS NOT NULL AND flg_clean_calib <> 99
),
po AS (
  SELECT cast(codmes AS int) AS codmes, tip_doc, key_value,
         max(cast(max_saldo_ent AS double)) AS maxs,
         max(cast(saldo_m0_ent  AS double)) AS s0
  FROM disc_model_owner.ds_adm_bpe_bankbn_po
  WHERE marca_entidad = 'IBK'
  GROUP BY cast(codmes AS int), tip_doc, key_value
),
j AS (
  SELECT c.codmes,
         CASE WHEN p.codmes IS NULL THEN 0 ELSE 1 END AS en_po,
         p.maxs, p.s0
  FROM cal c
  LEFT JOIN po p ON p.codmes = c.codmes AND p.tip_doc = c.tip_doc AND p.key_value = c.key_value
)
SELECT CASE WHEN codmes >= 202501 THEN cast(codmes AS varchar) ELSE 'A_hist_pre2025' END AS bucket,
       count(*) AS n_cal_ibk,
       sum(en_po) AS n_en_po,
       count_if(maxs >= 50000) AS ge50k_maxsaldo_prealta,
       count_if(s0 >= 50000)   AS ge50k_saldo_m0,
       round(approx_percentile(maxs, 0.5), 0) AS maxs_p50,
       round(approx_percentile(s0, 0.5), 0)   AS s0_p50,
       round(approx_percentile(s0, 0.9), 0)   AS s0_p90
FROM j
GROUP BY CASE WHEN codmes >= 202501 THEN cast(codmes AS varchar) ELSE 'A_hist_pre2025' END
ORDER BY bucket
