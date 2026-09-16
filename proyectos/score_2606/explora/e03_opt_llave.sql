-- e03 formato llave opt sin exponer key_value. char vs bytes, cero inicial, dominio tipdoc. Scan opt prob no nula.
SELECT CAST(cod_tip_doc AS varchar) AS cod_tip_doc,
       length(key_value) AS len_chars,
       length(to_utf8(key_value)) AS len_bytes,
       CASE WHEN substr(key_value, 1, 1) = '0' THEN 1 ELSE 0 END AS empieza_cero,
       COUNT(*) AS n
FROM disc_riesgos.scr_vcbankv3_repro_opt_
WHERE probabilidad IS NOT NULL
GROUP BY CAST(cod_tip_doc AS varchar), length(key_value), length(to_utf8(key_value)),
         CASE WHEN substr(key_value, 1, 1) = '0' THEN 1 ELSE 0 END
ORDER BY n DESC
