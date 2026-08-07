-- Cuanta diferenciacion compra el punto, abierto por nivel R del score distrital.
-- Agregado de 6 filas.
SELECT s.r_nivel,
       COUNT(*) AS clientes,
       ROUND(STDDEV(e.et_inu), 4) AS sd_inundacion,
       ROUND(STDDEV(e.et_mm ), 4) AS sd_mov_masa,
       ROUND(APPROX_PERCENTILE(e.et_inu, 0.9) - APPROX_PERCENTILE(e.et_inu, 0.1), 4) AS rango_p10_p90
FROM disc_model_owner.fen_exposicion_cliente e
JOIN disc_model_owner.fen_score_v6 s ON s.cod_ubigeo = e.ubigeo
GROUP BY s.r_nivel ORDER BY s.r_nivel
