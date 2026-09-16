-- e04 cruce opt vs ds_rtd_rskvol tipo_ingreso 202401 y 202606. match-rate con SUBSTR(subject_id,3). Scan opt+rskvol 2 meses.
SELECT o.codmes, COUNT(*) AS n_opt,
       SUM(CASE WHEN t.key_value IS NOT NULL THEN 1 ELSE 0 END) AS n_match_tipoing
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
  SELECT DISTINCT CAST(periodo AS varchar) AS codmes, SUBSTR(subject_id, 3) AS key_value, CAST(tip_doc AS varchar) AS tipdoc
  FROM e_perm_aws.ds_rtd_rskvol_cas_ingr_ir
  WHERE CAST(numcarga AS INT) = 1 AND CAST(periodo AS varchar) IN ('202401', '202606')
) t ON o.key_value = t.key_value AND o.tipdoc = t.tipdoc AND o.codmes = t.codmes
GROUP BY o.codmes
ORDER BY o.codmes
