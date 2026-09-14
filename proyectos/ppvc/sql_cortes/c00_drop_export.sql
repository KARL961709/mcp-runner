-- c00. Drop de la tabla de export de cortes (Athena libera metadata. Si re-corres, vaciar antes s3 <S3_DATOS>/cortes_ppfacil/).
DROP TABLE IF EXISTS disc_model_owner.tmp_cortes_ppfacil_export
