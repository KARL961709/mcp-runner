-- qa_0b_ventanas.sql | ventana y volumen reales de las 4 tablas finales: dice si corrio el build viejo (201506) o el nuevo (201802)
SELECT 'po' AS tabla, min(codmes) AS codmes_min, max(codmes) AS codmes_max,
       count(DISTINCT codmes) AS meses, count(1) AS filas,
       count(1) - count(DISTINCT CAST(codmes AS VARCHAR) || tip_doc || key_value) AS dup_grano
FROM disc_model_owner.ds_adm_bpe_bankbn_po
UNION ALL
SELECT 'mad', min(codmes), max(codmes), count(DISTINCT codmes), count(1),
       count(1) - count(DISTINCT CAST(codmes AS VARCHAR) || tip_doc || key_value)
FROM disc_model_owner.ds_adm_bpe_bankbn_mad
UNION ALL
SELECT 'drivers', min(codmes), max(codmes), count(DISTINCT codmes), count(1),
       count(1) - count(DISTINCT CAST(codmes AS VARCHAR) || tip_doc || key_value)
FROM disc_model_owner.ds_adm_bpe_bankbn_drivers
UNION ALL
SELECT 'cal', min(codmes), max(codmes), count(DISTINCT codmes), count(1),
       count(1) - count(DISTINCT CAST(codmes AS VARCHAR) || tip_doc || key_value)
FROM disc_model_owner.ds_adm_bpe_bankbn_cal
ORDER BY tabla
