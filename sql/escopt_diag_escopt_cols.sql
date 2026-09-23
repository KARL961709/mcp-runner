-- escopt_diag_escopt_cols.sql | columnas de scr_admbankbpe_calibrado_202607_escopt. Agregado.
SELECT column_name, data_type FROM information_schema.columns
WHERE table_schema='disc_model_owner' AND table_name='scr_admbankbpe_calibrado_202607_escopt' ORDER BY ordinal_position
