-- desemb_cmp_overlays.sql | compara los DOS overlays sobre el MISMO pd_pit, por sub-segmento, ventana reciente 202501-202507 (maduras). pdf_viejo = overlay PJ 0.85 (por personeria), pdf_rec = overlay REC ya materializado. Prueba: PN_NUEVO identico en todo, PJ_NUEVO solo el viejo lo baja (0.85), recurrentes cambian de 0.85 a 0.72/0.82. Read-only, agregado.
SELECT seg,
  COUNT(*) AS n,
  ROUND(100*AVG(pd_pit), 2) AS pd_pit_sin_ov,
  ROUND(100*AVG(pd_pit * CASE WHEN cod_tip_doc <> '1' AND cod_mes >= 202504 THEN 0.85 ELSE 1.0 END), 2) AS pdf_viejo_pj085,
  ROUND(100*AVG(pd_pit_final), 2) AS pdf_rec,
  ROUND(100*AVG(target_12m), 2) AS rd12
FROM disc_model_owner.b46029_desemb_maestra_rec_202609
WHERE flg_cruce = 1 AND meses_madurez = 12 AND cod_mes BETWEEN 202501 AND 202507
GROUP BY seg
ORDER BY seg
