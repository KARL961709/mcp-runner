-- desemb_corrm_migra.sql | MIGRACION de grupos: maestra VIEJA (b46029_desemb_maestra_rec_202609, cruce viejo cod_mes) vs CORREGIDA V1 (cruce cod_mes-1). Diagonal = sin cambio. Demuestra que el fix no mueve significativo. Agregado.
SELECT o.grupo_cal AS g_viejo, n.grupo_cal AS g_corregido, COUNT(*) AS n
FROM disc_model_owner.b46029_desemb_maestra_rec_202609 o
JOIN disc_model_owner.b46029_desemb_maestra_corrv1_202609 n ON o.cod_mes=n.cod_mes AND o.cod_tip_doc=n.cod_tip_doc AND o.key_value=n.key_value
WHERE o.flg_cruce=1 AND n.flg_cruce=1
GROUP BY o.grupo_cal, n.grupo_cal
ORDER BY o.grupo_cal, n.grupo_cal
