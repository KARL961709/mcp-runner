-- c01 LA CADENA DE CALIBRACION SIGUE VIVA -- contraste contra las tablas FEN vacias
SELECT 'ds_po_origpp TODO'  AS tabla, count(*) AS n_filas, count(DISTINCT codmes) AS n_meses
FROM disc_model_owner.pp_vc_ds_po_origpp
UNION ALL
SELECT 'ds_po_origpp CALIB', count(*), count(DISTINCT codmes)
FROM disc_model_owner.pp_vc_ds_po_origpp
WHERE cod_instit_financiera = '00002' AND flg_calib_rd = 1
UNION ALL
SELECT 'master_ibk', count(*), count(DISTINCT codmes)
FROM disc_model_owner.pp_vc_master_ibk
UNION ALL
SELECT 'pp_vc_drivers', count(*), count(DISTINCT codmes)
FROM disc_model_owner.pp_vc_drivers
ORDER BY 1
