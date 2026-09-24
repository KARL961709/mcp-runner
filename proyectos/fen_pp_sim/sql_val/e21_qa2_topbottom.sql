-- e21_qa2_topbottom.sql | QA sanity: top5 (deben ser caletas de pesca, s alto) y bottom5 (s bajo, servicios/construccion)
SELECT ubigeo, s_raw, s_norm, CASE WHEN hi <= 5 THEN 'TOP' ELSE 'BOTTOM' END AS extremo
FROM (
  SELECT ubigeo, ROUND(s_raw,3) AS s_raw, ROUND(s_norm,4) AS s_norm,
         ROW_NUMBER() OVER (ORDER BY s_raw DESC) AS hi,
         ROW_NUMBER() OVER (ORDER BY s_raw ASC)  AS lo
  FROM disc_model_owner.fen_s_indirecto_empleo_2026
) q
WHERE hi <= 5 OR lo <= 5
ORDER BY s_raw DESC