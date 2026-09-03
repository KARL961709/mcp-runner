-- a99. DEDUP: 0 filas = grano unico (codmes, tip_doc, key_value) dentro de sub_producto='EC'.
SELECT codmes, tip_doc, key_value, COUNT(*) AS n
FROM disc_model_owner.altas_ec_cal
GROUP BY codmes, tip_doc, key_value HAVING COUNT(*) > 1 LIMIT 20