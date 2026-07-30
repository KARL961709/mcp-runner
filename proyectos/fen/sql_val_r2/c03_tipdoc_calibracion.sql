-- c03 GRANO Y TIPO DE DOCUMENTO de la poblacion de calibracion
--     tip_doc <> 1 no cruza RENIEC -- acota el techo de c02
SELECT tip_doc, subproducto_,
       count(*)                  AS n_filas,
       count(DISTINCT id_value)  AS n_personas,
       count(DISTINCT codmes)    AS n_meses
FROM disc_model_owner.pp_vc_ds_po_origpp
WHERE cod_instit_financiera = '00002' AND flg_calib_rd = 1
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 20
