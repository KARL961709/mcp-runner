-- c02 EL NUMERO QUE DECIDE LA PROPUESTA
--     que fraccion de la poblacion de calibracion PP se puede geolocalizar por id_value -> RENIEC
SELECT substr(a.codmes, 1, 4) AS anio,
       count(*)                                                                  AS n_calib,
       round(100.0 * avg(CASE WHEN r.key_value IS NOT NULL THEN 1 ELSE 0 END), 2) AS pct_en_reniec,
       round(100.0 * avg(CASE WHEN r.dep IS NOT NULL AND r.pro IS NOT NULL
                              AND r.dis IS NOT NULL THEN 1 ELSE 0 END), 2)        AS pct_con_distrito
FROM disc_model_owner.pp_vc_ds_po_origpp a
LEFT JOIN (SELECT key_value,
                  max(trim(upper(dep_ubi_domicilio))) AS dep,
                  max(trim(upper(pro_ubi_domicilio))) AS pro,
                  max(trim(upper(dis_ubi_domicilio))) AS dis
           FROM e_perm_aws.t_mst_reniec_rsk
           WHERE tip_doc = '1'
           GROUP BY key_value) r
       ON r.key_value = a.id_value
WHERE a.cod_instit_financiera = '00002' AND a.flg_calib_rd = 1
GROUP BY 1
ORDER BY 1
