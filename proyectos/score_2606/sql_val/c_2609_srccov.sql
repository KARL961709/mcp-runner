-- c_2609_srccov. Cobertura de disc_riesgos.scr_vcbankv3_repro_: meses, probabilidad poblada, personas, DNI.
--   Confirma que 202609 tenga probabilidad. Si falla por columna, mirar c_2609_schema para el nombre real.
SELECT CAST(codmes AS varchar) AS codmes, COUNT(*) AS n,
  SUM(CASE WHEN probabilidad IS NOT NULL THEN 1 ELSE 0 END) AS n_prob,
  COUNT(DISTINCT key_value) AS n_pers,
  SUM(CASE WHEN CAST(cod_tip_doc AS varchar) = '1' THEN 1 ELSE 0 END) AS n_dni
FROM disc_riesgos.scr_vcbankv3_repro_
GROUP BY CAST(codmes AS varchar)
ORDER BY codmes
