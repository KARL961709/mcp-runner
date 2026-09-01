-- i08. G10 madurez + monotonia del target (ibk clean): t01..t12 no decreciente, frontera de NULL.
SELECT codmes,
  ROUND(AVG(CAST(target_01m AS double)), 4) AS t01, ROUND(AVG(CAST(target_03m AS double)), 4) AS t03,
  ROUND(AVG(CAST(target_06m AS double)), 4) AS t06, ROUND(AVG(CAST(target_09m AS double)), 4) AS t09,
  ROUND(AVG(CAST(target_12m AS double)), 4) AS t12,
  SUM(CASE WHEN target_12m IS NULL THEN 1 ELSE 0 END) AS n_t12_null,
  SUM(CASE WHEN target_06m IS NULL THEN 1 ELSE 0 END) AS n_t06_null
FROM disc_model_owner.ds_adm_tcbank_cal
WHERE flg_ibk = 1 AND flg_clean = 1
GROUP BY codmes
ORDER BY codmes