-- k00 esquema: confirma columnas del universo scoreado 202608 y las llaves del score directo/reest reniec ANTES del CTAS de 14M. Read-only, targeted (no escanea el catalogo entero)
SELECT 'universo' AS tabla, column_name, data_type
FROM information_schema.columns
WHERE table_schema='disc_model_owner' AND table_name='scr_vcadmbnk_final_hist_rsk_cal_2606_2608'
  AND column_name IN ('codmes','key_value','tipo_ingreso','nodo','prob_modelo_cal_ppfacil','prob_modelo_cal_ppcd','puntuacion_modelo_cal_ppfacil','puntuacion_modelo_cal_ppcd')
UNION ALL
SELECT 'reniec' AS tabla, column_name, data_type
FROM information_schema.columns
WHERE table_schema='disc_model_owner' AND table_name='mca_bd_reniec_xy_r_reest'
  AND column_name IN ('key_value','r_nivel','r_nivel_geo','r_nivel_reest','ubigeo_inei_nodo','flg_nodo','patron_evento','flg_regimen','dist_ma_m','exp25','exp50')
ORDER BY tabla, column_name
