-- desemb_corrm_migra_v1.sql | MIGRACION de grupos: version anterior SIN correccion + solo overlay recurrente (b46029_desemb_maestra_rec_202609) vs CORREGIDA V1. Matriz g_viejo x g_corregido. Diagonal = sin cambio. Agregado.
SELECT o.grupo_cal AS g_viejo_rec, n.grupo_cal AS g_corr_v1, COUNT(*) AS n
FROM disc_model_owner.b46029_desemb_maestra_rec_202609 o
JOIN disc_model_owner.b46029_desemb_maestra_corrv1_202609 n ON o.cod_mes=n.cod_mes AND o.cod_tip_doc=n.cod_tip_doc AND o.key_value=n.key_value
WHERE o.flg_cruce=1 AND n.flg_cruce=1
GROUP BY o.grupo_cal, n.grupo_cal ORDER BY o.grupo_cal, n.grupo_cal
