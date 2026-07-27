-- 91_export_cal.sql | parquet del universo elegible Top-4, 201802-202606, con todos los flags. El 99 no entra
CREATE TABLE disc_model_owner.ds_adm_bpe_bankbn_cal_export
WITH (
    format               = 'PARQUET',
    parquet_compression  = 'SNAPPY',
    external_location    = '<S3_DATOS>/cal/'
) AS
SELECT *
FROM disc_model_owner.ds_adm_bpe_bankbn_cal
WHERE flg_clean IN (0, 1)
