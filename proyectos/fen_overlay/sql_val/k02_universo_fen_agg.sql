-- k02 universo FEN 202608 AGREGADO para EMBEBER en el artifact: celdas grado x R_reest x tipo x pac sobre los ~14M, con n + PD calibrada media (PP Facil). SIN RD (universo no maduro). Lee la tabla k01. Devuelve pocas filas -> vuelve pegable por _resumen/CSV. Grado por los cortes de score de Carlos (G1>=993 ... GR)
WITH g AS (
  SELECT
    CASE WHEN puntuacion_modelo_cal_ppfacil >= 993 THEN 'G1' WHEN puntuacion_modelo_cal_ppfacil >= 972 THEN 'G2'
         WHEN puntuacion_modelo_cal_ppfacil >= 959 THEN 'G3' WHEN puntuacion_modelo_cal_ppfacil >= 921 THEN 'G4'
         WHEN puntuacion_modelo_cal_ppfacil >= 884 THEN 'G5' WHEN puntuacion_modelo_cal_ppfacil >= 850 THEN 'G6'
         ELSE 'GR' END AS grado,
    r_reest AS r,
    tipo_ingreso AS tipo,
    pac,
    prob_modelo_cal_ppfacil AS pd
  FROM disc_model_owner.fen_universo_202608_cal
)
SELECT grado, r, tipo, pac,
  count(*) AS n,
  round(avg(pd), 5) AS pd
FROM g
GROUP BY grado, r, tipo, pac
ORDER BY grado, r, tipo, pac
