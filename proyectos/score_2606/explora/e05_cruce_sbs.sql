-- e05 cruce opt vs t_mst_ctarcc_rsk SBS llave directa 202401 y 202606. match-rate. Scan opt 2 meses + ctarcc.
SELECT o.codmes, COUNT(*) AS n_opt,
       SUM(CASE WHEN b.key_value IS NOT NULL THEN 1 ELSE 0 END) AS n_match_sbs
FROM (
  SELECT codmes, key_value, tipdoc FROM (
    SELECT CAST(codmes AS varchar) AS codmes, key_value, CAST(cod_tip_doc AS varchar) AS tipdoc,
           ROW_NUMBER() OVER (PARTITION BY CAST(codmes AS varchar), key_value, CAST(cod_tip_doc AS varchar) ORDER BY probabilidad DESC) AS rn
    FROM disc_riesgos.scr_vcbankv3_repro_opt_
    WHERE probabilidad IS NOT NULL AND CAST(cod_tip_doc AS varchar) = '1'
      AND CAST(codmes AS varchar) IN ('202401', '202606')
  ) WHERE rn = 1
) o
LEFT JOIN (
  SELECT DISTINCT CAST(tip_doc AS varchar) AS tipdoc, key_value
  FROM e_perm_aws.t_mst_ctarcc_rsk
  WHERE tip_doc = '1' AND tip_persona = '1' AND key_value IS NOT NULL AND sbs_value IS NOT NULL
) b ON o.key_value = b.key_value AND o.tipdoc = b.tipdoc
GROUP BY o.codmes
ORDER BY o.codmes
