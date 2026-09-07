-- f02 grano y ventana de disc_model_owner.ds_adm_pp_cdpp_cal
SELECT count(*) AS n_filas, count(DISTINCT codmes) AS n_meses, min(codmes) AS codmes_min, max(codmes) AS codmes_max
FROM disc_model_owner.ds_adm_pp_cdpp_cal
