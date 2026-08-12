-- 96_reniec_supervivencia.sql | mide U1: si la tasa de match contra RENIEC cae hacia atras en el tiempo, la foto de hoy no representa el pasado y el filtro de edad arrastra sesgo de supervivencia que crece justo donde queremos ganar historia. Tambien separa las dos ramas que la PO funde en la etiqueta EDAD
SELECT substr(a.p_codmes, 1, 4)                                                             AS anio,
       count(*)                                                                             AS n_poblacion,
       sum(CASE WHEN r.key_value IS NOT NULL THEN 1 ELSE 0 END)                              AS con_reniec,
       round(100.0 * sum(CASE WHEN r.key_value IS NOT NULL THEN 1 ELSE 0 END) / count(*), 3) AS pct_match,
       sum(CASE WHEN r.key_value IS NULL THEN 1 ELSE 0 END)                                  AS sin_match,
       sum(CASE WHEN r.key_value IS NOT NULL
                 AND coalesce(CAST(r.flg_inhabilitado AS VARCHAR), '0') <> '0'
                THEN 1 ELSE 0 END)                                                           AS n_inhabilitado,
       sum(CASE WHEN a.dsc_flg_malo_12m = 'EDAD' THEN 1 ELSE 0 END)                          AS n_bucket_edad,
       sum(CASE WHEN a.dsc_flg_malo_12m = 'EDAD' AND r.key_value IS NULL THEN 1 ELSE 0 END)  AS edad_sin_match
FROM e_perm_aws.ds_flg_admtcnobk1_rsk a
LEFT JOIN e_perm_aws.t_mst_reniec_rsk r
       ON a.tip_doc = r.tip_doc
      AND a.id_value = r.key_value
WHERE a.prelacion_00m = 1
GROUP BY substr(a.p_codmes, 1, 4)
ORDER BY anio
