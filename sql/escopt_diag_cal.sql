-- escopt_diag_cal.sql | vintages del calibrado oficial V2 (bankbn) disponibles en disc_model_owner + su max p_codmes. Agregado.
SELECT table_name FROM information_schema.tables
WHERE table_schema='disc_model_owner' AND table_name LIKE 'scr_admbankbpe_calibrado%'
ORDER BY table_name
