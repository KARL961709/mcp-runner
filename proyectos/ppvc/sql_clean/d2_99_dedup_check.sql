-- d2_99. DEDUP CHECK: 0 filas = sin duplicados por (codmes, tip_doc, key_value).
SELECT codmes, tip_doc, key_value, COUNT(*) AS n
FROM disc_model_owner.drv_clean_ppvc
GROUP BY codmes, tip_doc, key_value
HAVING COUNT(*) > 1
LIMIT 20