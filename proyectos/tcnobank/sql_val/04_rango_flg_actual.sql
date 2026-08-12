-- 04_rango_flg_actual.sql | volumen y ventana disponible de la tabla de flags vigente, que es la que define cuanta historia hay para calibrar
SELECT count(*)                                                  AS n_filas,
       count(DISTINCT p_codmes)                                  AS meses,
       min(p_codmes)                                             AS codmes_min,
       max(p_codmes)                                             AS codmes_max,
       count(DISTINCT id_value)                                  AS clientes,
       count(DISTINCT nombre_instit_financiera)                  AS entidades,
       sum(CASE WHEN score IS NULL THEN 1 ELSE 0 END)            AS sin_score,
       sum(CASE WHEN flg_est = 1 THEN 1 ELSE 0 END)              AS n_est,
       sum(CASE WHEN flg_per = 1 THEN 1 ELSE 0 END)              AS n_per,
       sum(CASE WHEN prelacion_00m = 1 THEN 1 ELSE 0 END)        AS n_prelacion00
FROM e_perm_aws.ds_flg_admtcnobk1_rsk
