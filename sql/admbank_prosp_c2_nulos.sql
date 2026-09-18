-- QA[2] nulos en calibracion + que ninguna caida quedo (0 interseccion)
SELECT COUNT(*) AS n, SUM(CASE WHEN prob_modelo_cal IS NULL THEN 1 ELSE 0 END) AS prob_null, SUM(CASE WHEN grupos_cal IS NULL THEN 1 ELSE 0 END) AS grupo_null,
  SUM(CASE WHEN key_value IN (SELECT key_value FROM disc_model_owner.caidas_202608_admbank) THEN 1 ELSE 0 END) AS caidas_no_excluidas
FROM disc_model_owner.admbank_prosp_202608
