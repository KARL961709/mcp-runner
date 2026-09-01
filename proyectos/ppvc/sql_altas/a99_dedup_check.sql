-- a99. DEDUP CHECK: 0 filas = sin duplicados por (codmes, tip_doc, key_value).
SELECT codmes, tip_doc, key_value, COUNT(*) AS n
FROM disc_model_owner.altas_adm_pp_cdpp_cal
GROUP BY codmes, tip_doc, key_value
HAVING COUNT(*) > 1
LIMIT 20