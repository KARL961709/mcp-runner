-- 09_verifica_offset.sql | PASO 0: verifica el desfase real entre la particion p_codmes del score (scr_admbankbpe_rsk.probabilidad) y el codmes de la alta (ds_adm_bpe_bankbn_cal.pd_raw). Une por tip_doc+key_value y prueba offset 0/+1/+2 meses (p_codmes = codmes, codmes-1, codmes-2). El offset correcto es el que maximiza join y IGUALDAD pd_raw = probabilidad (deben ser la misma cifra por dos caminos). Restringido a 202401-202606 para abaratar, el offset no depende del periodo. READ-ONLY
WITH ds AS (
  SELECT cast(tip_doc AS varchar) AS td, key_value AS kv, cast(codmes AS int) AS dcm,
         cast(date_format(date_parse(cast(codmes AS varchar), '%Y%m') - interval '1' month, '%Y%m') AS int) AS dcm_m1,
         cast(date_format(date_parse(cast(codmes AS varchar), '%Y%m') - interval '2' month, '%Y%m') AS int) AS dcm_m2,
         cast(pd_raw AS double) AS pdr
  FROM disc_model_owner.ds_adm_bpe_bankbn_cal_202607
  WHERE pd_raw IS NOT NULL AND cast(codmes AS int) BETWEEN 202401 AND 202606
),
scr AS (
  SELECT cast(tip_doc AS varchar) AS td, key_value AS kv, cast(p_codmes AS int) AS pcm,
         max(cast(probabilidad AS double)) AS prob
  FROM e_perm_aws.scr_admbankbpe_rsk
  WHERE probabilidad IS NOT NULL AND p_codmes BETWEEN '202312' AND '202606'
  GROUP BY cast(tip_doc AS varchar), key_value, cast(p_codmes AS int)
)
SELECT count(*) AS n_ds,
  sum(CASE WHEN s0.prob IS NOT NULL THEN 1 ELSE 0 END) AS join_off0,
  sum(CASE WHEN abs(s0.prob - ds.pdr) < 1e-5 THEN 1 ELSE 0 END) AS igual_off0,
  sum(CASE WHEN s1.prob IS NOT NULL THEN 1 ELSE 0 END) AS join_off1,
  sum(CASE WHEN abs(s1.prob - ds.pdr) < 1e-5 THEN 1 ELSE 0 END) AS igual_off1,
  sum(CASE WHEN s2.prob IS NOT NULL THEN 1 ELSE 0 END) AS join_off2,
  sum(CASE WHEN abs(s2.prob - ds.pdr) < 1e-5 THEN 1 ELSE 0 END) AS igual_off2
FROM ds
LEFT JOIN scr s0 ON s0.td = ds.td AND s0.kv = ds.kv AND s0.pcm = ds.dcm
LEFT JOIN scr s1 ON s1.td = ds.td AND s1.kv = ds.kv AND s1.pcm = ds.dcm_m1
LEFT JOIN scr s2 ON s2.td = ds.td AND s2.kv = ds.kv AND s2.pcm = ds.dcm_m2
