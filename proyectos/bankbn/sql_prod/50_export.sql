-- ============================================================================
-- 50. EXPORT parquets  (<S3_DATOS> = raiz S3 del proyecto; <CODMES>)
-- ============================================================================
DROP TABLE IF EXISTS disc_model_owner.ds_adm_bpe_bankbn_export_clean;
CREATE TABLE disc_model_owner.ds_adm_bpe_bankbn_export_clean
WITH (format='PARQUET', external_location='<S3_DATOS>/clean/codmes=<CODMES>/')
AS SELECT * FROM disc_model_owner.ds_adm_bpe_bankbn_cal WHERE flg_clean = 1 AND codmes = '<CODMES>';

DROP TABLE IF EXISTS disc_model_owner.ds_adm_bpe_bankbn_export_dirty;
CREATE TABLE disc_model_owner.ds_adm_bpe_bankbn_export_dirty
WITH (format='PARQUET', external_location='<S3_DATOS>/dirty/codmes=<CODMES>/')
AS SELECT * FROM disc_model_owner.ds_adm_bpe_bankbn_cal WHERE flg_clean = 0 AND codmes = '<CODMES>';
