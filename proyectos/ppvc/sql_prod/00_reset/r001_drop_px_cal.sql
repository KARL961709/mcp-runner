-- ============================================================================
-- r001. DROP del parquet export _cal de PP VC (tabla externa).
--   OJO: DROP TABLE no limpia S3. Antes de RE-crear, vaciar el prefijo
--   <S3_DATOS>/cal/ o el CTAS de 90_px_cal falla por location no vacia.
--   En la primera corrida no hace falta (la tabla no existe).
-- ============================================================================
DROP TABLE IF EXISTS disc_model_owner.ds_adm_pp_cdpp_px_cal
