-- a99. DEDUP: 0 filas = grano unico (codmes, tip_doc, key_value, cod_instit_financiera).
SELECT codmes, tip_doc, key_value, cod_instit_financiera, COUNT(*) AS n
FROM disc_model_owner.altas_adm_tcbank_cal
GROUP BY codmes, tip_doc, key_value, cod_instit_financiera HAVING COUNT(*) > 1 LIMIT 20