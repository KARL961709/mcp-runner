-- c_2609_reconpd. GATE CRITICO (E2): la probabilidad de la fuente nueva vcbankv3_repro DEBE ser el mismo
--   score VC que vcadmbnk_final_hist_rsk (sobre el que se calibro). Reconcilia en el traslape 202606-202608
--   con el MISMO dedup del driver (rn=1, cod_tip_doc=1, prob not null). n_diff~0 y max_diff~1e-7 -> mismo score.
--   Si n_diff es masivo o max_diff grande -> v3 es OTRO modelo y NO se puede aplicar la calibracion.
WITH v3 AS (
  SELECT CAST(codmes AS varchar) AS codmes, key_value, CAST(cod_tip_doc AS varchar) AS cod_tip_doc, CAST(probabilidad AS double) AS pd,
         ROW_NUMBER() OVER (PARTITION BY codmes, key_value, cod_tip_doc ORDER BY probabilidad DESC) AS rn
  FROM disc_riesgos.scr_vcbankv3_repro_
  WHERE probabilidad IS NOT NULL AND CAST(cod_tip_doc AS varchar) = '1'
    AND CAST(codmes AS varchar) BETWEEN '202606' AND '202608'
),
adm AS (
  SELECT CAST(codmes AS varchar) AS codmes, key_value, CAST(cod_tip_doc AS varchar) AS cod_tip_doc, CAST(probabilidad AS double) AS pd,
         ROW_NUMBER() OVER (PARTITION BY codmes, key_value, cod_tip_doc ORDER BY probabilidad DESC) AS rn
  FROM d_perm_aws.scr_vcadmbnk_final_hist_rsk
  WHERE probabilidad IS NOT NULL AND cod_tip_doc = '1'
    AND CAST(codmes AS varchar) BETWEEN '202606' AND '202608'
)
SELECT v3.codmes,
  COUNT(*) AS n_join,
  SUM(CASE WHEN ABS(v3.pd - adm.pd) > 1e-5 THEN 1 ELSE 0 END) AS n_diff,
  ROUND(MAX(ABS(v3.pd - adm.pd)), 8) AS max_diff,
  ROUND(AVG(v3.pd), 6) AS avg_v3,
  ROUND(AVG(adm.pd), 6) AS avg_adm
FROM v3
JOIN adm ON v3.codmes = adm.codmes AND v3.key_value = adm.key_value AND v3.cod_tip_doc = adm.cod_tip_doc AND v3.rn = 1 AND adm.rn = 1
GROUP BY v3.codmes
ORDER BY v3.codmes
