-- QA[6] IMPACTO DEL OVERLAY: migracion grupo_sin_overlay -> grupo_cal donde el overlay APLICA (RECURRENTE, cod_mes>=202501). Filas con g_sin<>g_con = clientes que mejoran de grupo por el overlay. Agregado.
SELECT seg,
  grupo_sin_overlay AS g_sin_overlay,
  grupo_cal AS g_con_overlay,
  COUNT(*) AS n
FROM disc_model_owner.b46029_desemb_maestra_rec_202609
WHERE flg_cruce = 1 AND seg IN ('PJ_RECURRENTE', 'PN_RECURRENTE') AND cod_mes >= 202501
GROUP BY seg, grupo_sin_overlay, grupo_cal
ORDER BY seg, grupo_sin_overlay, grupo_cal
