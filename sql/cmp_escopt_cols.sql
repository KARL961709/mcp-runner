-- cmp_escopt_cols.sql | columnas de la tabla ENVIADA para alinear llaves y campo v2_esc_opt. Agregado.
SELECT column_name, data_type FROM information_schema.columns
WHERE table_schema='d_perm_aws' AND table_name='scr_admbankbpe_rsk_cal_202501_202608' ORDER BY ordinal_position
