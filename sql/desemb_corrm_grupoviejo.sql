-- desemb_corrm_grupoviejo.sql | EXPORT del grupo de la version ANTERIOR (REC sin correccion): cod_mes, cod_tip_doc, key_value, grupo_cal. SELECT read-only, baja el CSV a output (para calcular la migracion local vs V1/V2 corregidas, sin crear tablas).
SELECT cod_mes, cod_tip_doc, key_value, grupo_cal
FROM disc_model_owner.b46029_desemb_maestra_rec_202609
WHERE flg_cruce = 1
