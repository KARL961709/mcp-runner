-- c04 HAY ESPACIO PARA UN OVERLAY REGIONAL?
--     si la poblacion de calibracion es casi toda Lima, un factor regional no tiene donde moverse
SELECT coalesce(r.dep, 'SIN_RENIEC') AS departamento,
       count(*)                                              AS n,
       round(100.0 * count(*) / sum(count(*)) OVER (), 2)     AS pct
FROM disc_model_owner.pp_vc_ds_po_origpp a
LEFT JOIN (SELECT key_value, max(trim(upper(dep_ubi_domicilio))) AS dep
           FROM e_perm_aws.t_mst_reniec_rsk
           WHERE tip_doc = '1'
           GROUP BY key_value) r
       ON r.key_value = a.id_value
WHERE a.cod_instit_financiera = '00002' AND a.flg_calib_rd = 1
GROUP BY 1
ORDER BY 2 DESC
LIMIT 30
