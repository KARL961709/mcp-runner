-- ============================================================================
-- r001. DROP de scr_ppvc_cal. DROP no limpia S3: vaciar <S3_DATOS>/scr_cal/ antes
--        de RE-crear (aws s3 rm ... --recursive). Primera corrida: no aplica.
-- ============================================================================
DROP TABLE IF EXISTS disc_model_owner.scr_ppvc_cal
