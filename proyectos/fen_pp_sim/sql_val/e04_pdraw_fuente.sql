-- e04_pdraw_fuente.sql | fuente del PD raw (prob_model) para PP: columnas de scr_vcbankv3_repro_opt_ y si hay dato en cod_mes 202609
SELECT 'A_cols' AS bloque, column_name AS a, data_type AS b
FROM information_schema.columns
WHERE table_schema = 'disc_riesgos' AND table_name = 'scr_vcbankv3_repro_opt_'
  AND regexp_like(lower(column_name), 'key|tip_doc|prob|cod_mes|codmes|pp|model')
UNION ALL
SELECT 'B_conteo_2609', CAST(COUNT(*) AS varchar), CAST(COUNT(DISTINCT key_value) AS varchar)
FROM disc_riesgos.scr_vcbankv3_repro_opt_
WHERE cod_mes = '202609'
ORDER BY bloque, a
