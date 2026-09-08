-- 08_flg1_vs_altas_rcc.sql | SOLO flg_desembolso=1: por cod_mes, cuantos desembolsos efectivos hay (n_flg1), cuantos matchean las altas de RCC del modelo BPE (ds_adm_bpe_bankbn_cal, exacto = mismo mes, asof = alta con codmes menor o igual), cuantos tienen pd_raw usable as-of desde el scorecard crudo scr_admbankbpe_rsk, y el pd_raw medio. Sirve para ver la diferencia vs altas RCC y evaluar el score de lo que nos quedamos. READ-ONLY
WITH ud AS (
  SELECT DISTINCT cast(cod_mes AS int) AS cm, cod_tip_doc AS td, key_value AS kv
  FROM d_perm_aws.user_desembolso
  WHERE flg_desembolso = 1
),
ds AS (
  SELECT DISTINCT tip_doc AS td, key_value AS kv, cast(codmes AS int) AS dcm
  FROM disc_model_owner.ds_adm_bpe_bankbn_cal_202607
),
scr AS (
  SELECT cast(tip_doc AS varchar) AS td, key_value AS kv, cast(p_codmes AS int) AS pcm,
         max(cast(probabilidad AS double)) AS pdr
  FROM e_perm_aws.scr_admbankbpe_rsk
  WHERE probabilidad IS NOT NULL AND p_codmes BETWEEN '202001' AND '202608'
  GROUP BY cast(tip_doc AS varchar), key_value, cast(p_codmes AS int)
),
dsm AS (
  SELECT ud.cm, ud.td, ud.kv,
    max(CASE WHEN d.dcm = ud.cm THEN 1 ELSE 0 END) AS ds_exacto,
    max(CASE WHEN d.dcm <= ud.cm THEN 1 ELSE 0 END) AS ds_asof
  FROM ud
  LEFT JOIN ds d ON d.td = ud.td AND d.kv = ud.kv
  GROUP BY ud.cm, ud.td, ud.kv
),
scm AS (
  SELECT ud.cm, ud.td, ud.kv, s.pdr,
    ROW_NUMBER() OVER (PARTITION BY ud.cm, ud.td, ud.kv ORDER BY s.pcm DESC) AS rn
  FROM ud
  LEFT JOIN scr s ON s.td = ud.td AND s.kv = ud.kv AND s.pcm <= ud.cm
),
sc1 AS (
  SELECT cm, td, kv, pdr FROM scm WHERE rn = 1
)
SELECT dsm.cm AS cod_mes,
  count(*) AS n_flg1,
  sum(dsm.ds_exacto) AS n_alta_rcc_exacto,
  sum(dsm.ds_asof) AS n_alta_rcc_asof,
  sum(CASE WHEN sc1.pdr IS NOT NULL THEN 1 ELSE 0 END) AS n_con_pdraw,
  round(100.0 * sum(CASE WHEN sc1.pdr IS NOT NULL THEN 1 ELSE 0 END) / count(*), 1) AS pct_con_pdraw,
  round(100.0 * avg(sc1.pdr), 3) AS pd_raw_medio_pct
FROM dsm
LEFT JOIN sc1 ON sc1.cm = dsm.cm AND sc1.td = dsm.td AND sc1.kv = dsm.kv
GROUP BY dsm.cm
ORDER BY dsm.cm
