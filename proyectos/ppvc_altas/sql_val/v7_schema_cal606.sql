-- =====================================================================================
-- v7 | ESQUEMA de la tabla de altas calibradas 202606 (nombrada en el CSV de control).
--   Buscamos: prob_modelo (raw) + trf_* (drivers) + prob_modelo_cal_ppfacil (PIT) +
--   subproducto. Si trae raw + drivers, derivamos las 3 PD (raw/ttc/pit) aqui mismo
--   y el build final es un solo query de bucket + agregacion. READ-ONLY.
--   Si no existe con este nombre, v6 (discovery) da el nombre real.
-- =====================================================================================
SELECT column_name, data_type, ordinal_position
FROM information_schema.columns
WHERE table_schema = 'd_perm_aws' AND table_name = 'scr_vcadmbnk_cal_202606'
ORDER BY ordinal_position
