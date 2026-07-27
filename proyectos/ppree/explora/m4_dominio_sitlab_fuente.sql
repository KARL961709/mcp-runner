-- ============================================================================
-- M4. U11 - DOMINIO LITERAL de sit_lab y fuente.
--     El CASE de Query_PO_calib#L288-296 enumera cuatro valores de fuente por
--     nombre; todo valor nuevo cae al ELSE INDEPENDIENTE en silencio. H16 midio
--     que sit_lab paso de 3 a 4 valores en 2024 y fuente de 10 a 13 en 2026.
-- ============================================================================
SELECT
  sit_lab,
  fuente,
  COUNT(*)                                                                       AS n,
  MIN(CAST(periodo AS VARCHAR))                                                  AS mes_min,
  MAX(CAST(periodo AS VARCHAR))                                                  AS mes_max,
  CASE WHEN fuente IN ('INFERIDO','EXPERIAN','SUSALUD','INFERIDO_IND_MVP') THEN 'ENUMERADO'
       ELSE 'CAE_AL_ELSE' END                                                    AS trato_en_el_case
FROM e_perm_aws.ds_rtd_rskvol_cas_ingr_ir
WHERE CAST(periodo AS INT) BETWEEN 202401 AND 202606
  AND CAST(numcarga AS INT) = 1
GROUP BY 1, 2
ORDER BY 3 DESC
