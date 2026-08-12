-- 21_madurez_real.sql | meses del target realmente observados por p_codmes, para fijar la ventana honesta en vez de confiar en la regla missing_12 mayor que 6 que deja pasar etiquetas de 12m armadas con 6 meses
SELECT p_codmes,
       count(*)                                                          AS n_est,
       sum(CASE WHEN nro_dm_m06 IS NULL THEN 1 ELSE 0 END)               AS sin_m06,
       sum(CASE WHEN nro_dm_m12 IS NULL THEN 1 ELSE 0 END)               AS sin_m12,
       round(avg(CAST(
              (CASE WHEN nro_dm_m01 IS NULL THEN 0 ELSE 1 END) + (CASE WHEN nro_dm_m02 IS NULL THEN 0 ELSE 1 END)
            + (CASE WHEN nro_dm_m03 IS NULL THEN 0 ELSE 1 END) + (CASE WHEN nro_dm_m04 IS NULL THEN 0 ELSE 1 END)
            + (CASE WHEN nro_dm_m05 IS NULL THEN 0 ELSE 1 END) + (CASE WHEN nro_dm_m06 IS NULL THEN 0 ELSE 1 END)
            + (CASE WHEN nro_dm_m07 IS NULL THEN 0 ELSE 1 END) + (CASE WHEN nro_dm_m08 IS NULL THEN 0 ELSE 1 END)
            + (CASE WHEN nro_dm_m09 IS NULL THEN 0 ELSE 1 END) + (CASE WHEN nro_dm_m10 IS NULL THEN 0 ELSE 1 END)
            + (CASE WHEN nro_dm_m11 IS NULL THEN 0 ELSE 1 END) + (CASE WHEN nro_dm_m12 IS NULL THEN 0 ELSE 1 END)
              AS DOUBLE)), 2)                                            AS meses_obs_prom,
       max(fech_creacion)                                                AS ult_creacion
FROM e_perm_aws.ds_flg_admtcnobk1_rsk
WHERE flg_est = 1
GROUP BY p_codmes
ORDER BY p_codmes
