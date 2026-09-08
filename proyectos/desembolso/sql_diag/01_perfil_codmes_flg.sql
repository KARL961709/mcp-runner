-- 01_perfil_codmes_flg.sql | perfil de d_perm_aws.user_desembolso por cod_mes y flg_desembolso: filas, clientes distintos y monto, para ver el rango de meses, el volumen y que significa flg_desembolso (oferta vs desembolso efectivo). READ-ONLY
SELECT cast(cod_mes AS int) AS cod_mes, flg_desembolso,
       count(*) AS n_filas,
       count(distinct key_value) AS n_cli,
       round(sum(cast(mto_desembolso AS double)) / 1000000.0, 2) AS mto_mm
FROM d_perm_aws.user_desembolso
GROUP BY cast(cod_mes AS int), flg_desembolso
ORDER BY cod_mes, flg_desembolso
