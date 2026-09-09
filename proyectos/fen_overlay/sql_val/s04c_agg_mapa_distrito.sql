-- s04c agg por DISTRITO para el mapa del artifact: agrega fen_overlay_altas_202605_202607 por ubigeo_dom -> n, depto, s media, y el R por-cliente de reniec RESUMIDO (share R4/R5 y R medio, para dir y reest). Con esto el mapa pinta el recorte duro / nivel R de RENIEC (no el grado v3) y CAMBIA al mover el toggle Ajuste Geo (r_reest) vs Directo (r_dir). Trae ambos resumenes: share_r45 (para la capa recorte duro) y avg_r (para colorear el nivel). Agregado ~1800 filas -> _resultados.txt
SELECT
  ubigeo_dom, depto,
  count(*) AS n,
  round(avg(COALESCE(s_total, 0.0)), 4)                     AS s,
  round(avg(CASE WHEN r_dir   >= 4 THEN 1.0 ELSE 0.0 END), 4) AS share_r45_dir,
  round(avg(CASE WHEN r_reest >= 4 THEN 1.0 ELSE 0.0 END), 4) AS share_r45_reest,
  round(avg(CAST(r_dir   AS double)), 3)                    AS avg_r_dir,
  round(avg(CAST(r_reest AS double)), 3)                    AS avg_r_reest
FROM disc_model_owner.fen_overlay_altas_202605_202607
GROUP BY ubigeo_dom, depto
