-- qa_s07_1a1: VALIDACION NO CIRCULAR del artifact Altas. Motor del overlay UNO-A-UNO POR CLIENTE en SQL sobre los 19.539, promediado. Debe coincidir con el artifact (base 9,70 · ESC2 11,06 · ESC1 12,67 · ESC32 10,32) dentro de ~0,05pp. Mismo motor que qa_s06_1a1 (Phi=normal_cdf, Phi-1=inverse_normal_cdf). Read-only, 3 filas
WITH b AS (
  SELECT
    pd,
    CAST(r_fis AS double)/5.0 AS d,
    CASE WHEN s_total IS NOT NULL THEN greatest(s_total,0)
         WHEN tipo_ingreso='NO_DEP' THEN 0.65 ELSE 0.25 END AS s,
    greatest(ibk_centrado,0) AS ibkp,
    CAST(pac AS double) AS pac
  FROM disc_model_owner.fen_altas_full_202605_202607
  WHERE pd > 0 AND pd < 1
),
sc AS (
  SELECT * FROM (VALUES ('ESC1',4.2,0.5,0.5,0.0),('ESC2',3.0,0.5,0.5,0.3),('ESC32',2.0,0.5,0.5,0.5)) AS t(esc,g,wf,wa,recup)
)
SELECT
  sc.esc,
  count(*) AS n,
  round(avg(b.pd)*100,3) AS base_pct,
  round(avg( normal_cdf(0.0,1.0,
      inverse_normal_cdf(0.0,1.0,b.pd)
      + 0.185*sc.g*b.pac*( (sc.wf*b.d + sc.wa*b.s + 0.25*b.d*b.s) * (1.0 - least(greatest(sc.recup + 0.02*b.ibkp, 0.0), 1.0)) )
    ) )*100, 3) AS estres_pct
FROM b CROSS JOIN sc
GROUP BY sc.esc
ORDER BY sc.esc
