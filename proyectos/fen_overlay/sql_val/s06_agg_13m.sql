-- s06_agg: celdas grado x r_fis x tipo x pac sobre los 13M (XY reest + sin-XY directo distrital fusionados por su r_fis, que es el R que se estresa), con n + PD calibrada media (PP Facil) + s + ibk. Para EMBEBER en el artifact universo (ahora 13M). Sin bucket a proposito (el engine estresa por r_fis, el bucket solo era provenance, ver s06_qa). Read-only, ~84 filas
SELECT
  grado,
  r_fis AS r,
  tipo_ingreso AS tipo,
  pac,
  count(*)                    AS n,
  round(avg(pd_ppfacil), 5)   AS pd,
  round(avg(s_total), 4)      AS s,
  round(avg(ibk_centrado), 4) AS ibk_c
FROM disc_model_owner.fen_overlay_input_13m_202608
GROUP BY grado, r_fis, tipo_ingreso, pac
ORDER BY grado, r_fis, tipo_ingreso, pac
