-- Colocar query para armar el target con la poblacion del modelo
SELECT 
    codmes as cod_mes,
    codmes_mrm,
    tip_doc as cod_tip_doc,
    id_value AS key_value,
    CASE WHEN dsc_flg_malo_12m = 'MALO' THEN 1 ELSE 0 END AS target_12m,
    codmes as p_codmes
FROM e_perm_aws.ds_flg_compppibk_rsk --Tabla Flag
WHERE codmes = '{codmes}'
    AND dsc_flg_malo_12m IN ('BUENO', 'MALO')