-- i03. G/dedup: 0 filas = grano unico por (codmes, tip_doc, key_value, cod_instit_financiera).
SELECT codmes, tip_doc, key_value, cod_instit_financiera, COUNT(*) AS n
FROM disc_model_owner.ds_adm_tcbank_cal
GROUP BY codmes, tip_doc, key_value, cod_instit_financiera
HAVING COUNT(*) > 1
LIMIT 20