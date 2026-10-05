-- w2610_02. Equivalencia del switch: opt.prob_model vs repro_.probabilidad en 202609 (comun).
--   Dedup ROW_NUMBER por (key_value, cod_tip_doc='1'). Si n_opt~n_repro~n_join y n_dif=0 -> el switch
--   es identico en score y poblacion (cosmetico). Si difiere -> el opt es re-scoreo, hay que entenderlo. Read-only.
WITH o AS (
  SELECT key_value, CAST(cod_tip_doc AS varchar) AS ctd, CAST(prob_model AS double) AS p,
         ROW_NUMBER() OVER (PARTITION BY key_value, CAST(cod_tip_doc AS varchar) ORDER BY prob_model DESC) AS rn
  FROM disc_riesgos.scr_vcbankv3_repro_opt_
  WHERE CAST(p_codmes AS varchar) = '202609' AND prob_model IS NOT NULL AND CAST(cod_tip_doc AS varchar) = '1'
),
r AS (
  SELECT key_value, CAST(cod_tip_doc AS varchar) AS ctd, CAST(probabilidad AS double) AS p,
         ROW_NUMBER() OVER (PARTITION BY key_value, CAST(cod_tip_doc AS varchar) ORDER BY probabilidad DESC) AS rn
  FROM disc_riesgos.scr_vcbankv3_repro_
  WHERE CAST(p_codmes AS varchar) = '202609' AND probabilidad IS NOT NULL AND CAST(cod_tip_doc AS varchar) = '1'
),
od AS (SELECT key_value, ctd, p FROM o WHERE rn = 1),
rd AS (SELECT key_value, ctd, p FROM r WHERE rn = 1)
SELECT
    (SELECT COUNT(*) FROM od) AS n_opt,
    (SELECT COUNT(*) FROM rd) AS n_repro,
    COUNT(*) AS n_join,
    SUM(CASE WHEN abs(od.p - rd.p) > 1e-9 THEN 1 ELSE 0 END) AS n_dif,
    max(abs(od.p - rd.p)) AS maxdif
FROM od JOIN rd ON od.key_value = rd.key_value AND od.ctd = rd.ctd
