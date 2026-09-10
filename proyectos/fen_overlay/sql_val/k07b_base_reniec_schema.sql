-- k07b: esquema de e_perm_aws.t_mst_reniec_rsk (base RENIEC madre que indica Carlos) para confirmar que trae key_value + ubigeo/domicilio DECLARADO. Con eso + grado_fen_v3.csv (R_nivel por distrito, ya lo tenemos local) se arma el r_dir distrital de los 3.83M sin XY. Read-only, information_schema
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'e_perm_aws' AND table_name = 't_mst_reniec_rsk'
ORDER BY ordinal_position
