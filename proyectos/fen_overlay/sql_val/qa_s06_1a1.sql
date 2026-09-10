-- qa_s06_1a1: VALIDACION NO CIRCULAR del artifact PEA. Corre el motor del overlay UNO-A-UNO POR CLIENTE en SQL (normal_cdf/inverse_normal_cdf de Trino = Phi y Phi-1) sobre los 12.93M, y promedia. Debe coincidir con lo que muestra el artifact (base 19,60 - ESC2 22,18 - ESC1 25,05 - ESC32 20,78) dentro de ~0,05pp (gap Jensen celda-vs-cliente). Si coincide, el artifact refleja el verdadero cambio por cliente, no un artefacto de agregacion. Motor: PD*=Phi(Phi-1(pd) + lam*g*pac*e'), e=wF*d+wA*s+kap*d*s, d=r_fis/5, s=greatest(s_total,0) o default tipo, e'=e*(1-rec), rec=clamp(recup+0.02*max(ibk,0),0,1), lam=0.185, kap=0.25. Read-only, 3 filas
WITH b AS (
  SELECT
    pd_ppfacil AS pd,
    CAST(r_fis AS double)/5.0 AS d,
    CASE WHEN s_total IS NOT NULL THEN greatest(s_total,0)
         WHEN tipo_ingreso='NO_DEP' THEN 0.65 ELSE 0.25 END AS s,
    greatest(ibk_centrado,0) AS ibkp,
    CAST(pac AS double) AS pac
  FROM disc_model_owner.fen_overlay_input_13m_202608
  WHERE pd_ppfacil > 0 AND pd_ppfacil < 1
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
