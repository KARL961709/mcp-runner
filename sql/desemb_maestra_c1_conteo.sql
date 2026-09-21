-- QA[1] CONTEO: maestra == base == user_desembolso (distinct 4-key). 0 filas perdidas.
SELECT 'conteo' AS chk,
  (SELECT COUNT(*) FROM disc_model_owner.b46029_desemb_maestra_rec_202609) AS n_maestra,
  (SELECT COUNT(*) FROM disc_model_owner.b46029_desemb_cal_202609) AS n_base,
  (SELECT COUNT(*) FROM (SELECT DISTINCT cod_mes,cod_tip_doc,key_value,desc_producto FROM d_perm_aws.user_desembolso)) AS n_user_desemb
