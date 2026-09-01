-- i03b. dedup en la poblacion fit (ibk): 0 filas = 1 alta IBK por (codmes, tip_doc, key_value).
SELECT codmes, tip_doc, key_value, COUNT(*) AS n
FROM disc_model_owner.ds_adm_tcbank_cal
WHERE flg_ibk = 1
GROUP BY codmes, tip_doc, key_value
HAVING COUNT(*) > 1
LIMIT 20