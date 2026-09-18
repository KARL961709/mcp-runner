-- QA[1] CONTEO: prosp = scoreados(202608) - caidas. Muestra scoreado, caidas cruzadas y final.
SELECT (SELECT COUNT(*) FROM disc_model_owner.admbank_prosp_202608) AS n_prosp,
  (SELECT COUNT(*) FROM e_perm_aws.scr_admbankbpe_rsk WHERE probabilidad IS NOT NULL AND modelo='ADMBANKBPE' AND CAST(p_codmes AS INT)=202608) AS n_scoreado,
  (SELECT COUNT(DISTINCT key_value) FROM disc_model_owner.caidas_202608_admbank) AS n_caidas_keys
