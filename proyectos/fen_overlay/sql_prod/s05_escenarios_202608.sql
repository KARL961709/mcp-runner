-- s05 escenarios 202608: materializa la PD estresada y el grado bajo los 6 escenarios de gobierno del simulador, por cliente del PEA 202608. Formato LARGO (6 filas por cliente, una por escenario). Lee fen_overlay_input_202608 (correr DESPUES de s03). Motor IDENTICO al artifact: PDx = Phi( Phi_inv(pd0) + lambda*gamma*pac*e*(1-rec) ), con lambda=sqrt(rho/(1-rho)) y rho=0.0332, e=wF*d+wA*s+kappa*d*s (kappa=0.25), d=r_reest/5 (R geo de produccion = Ajuste Geo), rec=clamp(recup+0.02*max(ibk_c,0),0,1), s=s_total real o proxy (NO_DEP 0.65 / DEP 0.25), pac=gate Pacifico (si pac=0 el shift es 0 y PDx=pd0). Grado por los cortes PD del libro. recorte_duro=1 si r_reest>=4 (politica de originacion RECHAZO, se aplica aguas abajo). Se estresan pd_ppfacil y pd_ppcd. Escenarios (gamma,wF,wA,recup) exactos del simulador. RE-crear: vaciar <S3_DATOS>/fen_overlay_escenarios_202608/
CREATE TABLE disc_model_owner.fen_overlay_escenarios_202608
WITH (format='PARQUET', write_compression='SNAPPY', external_location='<S3_DATOS>/fen_overlay_escenarios_202608/') AS
WITH b AS (
  SELECT
    key_value, codmes, tipo_ingreso, depto, ubigeo_dom, r_dir, r_reest, pac,
    CASE WHEN r_reest >= 4 THEN 1 ELSE 0 END AS recorte_duro,
    ibk_centrado, resiliente,
    pd_ppfacil AS pd_base_facil, pd_ppcd AS pd_base_cd,
    CAST(r_reest AS double) / 5.0 AS d,
    CASE WHEN s_total IS NOT NULL THEN greatest(s_total, 0.0)
         WHEN tipo_ingreso = 'NO_DEP' THEN 0.65 ELSE 0.25 END AS s,
    greatest(coalesce(ibk_centrado, 0.0), 0.0) AS ibkp,
    inverse_normal_cdf(0.0, 1.0, least(greatest(pd_ppfacil, 1e-9), 0.999999999)) AS z0_facil,
    inverse_normal_cdf(0.0, 1.0, least(greatest(pd_ppcd,    1e-9), 0.999999999)) AS z0_cd
  FROM disc_model_owner.fen_overlay_input_202608
),
esc AS (
  SELECT * FROM (VALUES
    (CAST('ESC1' AS varchar), CAST('Extraordinario - sin recuperacion' AS varchar), CAST(4.2 AS double), CAST(0.5 AS double), CAST(0.5 AS double), CAST(0.0 AS double)),
    ('ESC2',  'Fuerte - balanceado',        3.0, 0.5, 0.5, 0.3),
    ('ESC21', 'Fuerte - sesgo fisico',      3.0, 0.6, 0.4, 0.3),
    ('ESC22', 'Fuerte - con recuperacion',  3.0, 0.5, 0.5, 0.5),
    ('ESC31', 'Moderado - sesgo fisico',    2.0, 0.6, 0.4, 0.3),
    ('ESC32', 'Moderado - con recuperacion',2.0, 0.5, 0.5, 0.5)
  ) AS t(escenario, etiqueta, gamma, wf, wa, recup)
),
px AS (
  SELECT b.*, e.escenario, e.etiqueta, e.gamma, e.recup,
    normal_cdf(0.0, 1.0, b.z0_facil + sqrt(0.0332/(1-0.0332)) * e.gamma * b.pac * ((e.wf*b.d + e.wa*b.s + 0.25*b.d*b.s) * (1 - least(greatest(e.recup + 0.02*b.ibkp, 0.0), 1.0)))) AS pd_estres_facil,
    normal_cdf(0.0, 1.0, b.z0_cd    + sqrt(0.0332/(1-0.0332)) * e.gamma * b.pac * ((e.wf*b.d + e.wa*b.s + 0.25*b.d*b.s) * (1 - least(greatest(e.recup + 0.02*b.ibkp, 0.0), 1.0)))) AS pd_estres_cd
  FROM b CROSS JOIN esc e
)
SELECT
  key_value, codmes, tipo_ingreso, depto, ubigeo_dom, r_dir, r_reest, pac, recorte_duro,
  round(ibk_centrado, 4) AS ibk_centrado, resiliente,
  escenario, etiqueta, gamma, recup,
  round(pd_base_facil, 5) AS pd_base_facil,
  CASE WHEN pd_base_facil<=0.00871 THEN 'G1' WHEN pd_base_facil<=0.02581 THEN 'G2' WHEN pd_base_facil<=0.04542 THEN 'G3' WHEN pd_base_facil<=0.07551 THEN 'G4' WHEN pd_base_facil<=0.11283 THEN 'G5' WHEN pd_base_facil<=0.15813 THEN 'G6' ELSE 'GR' END AS grado_base_facil,
  round(pd_estres_facil, 5) AS pd_estres_facil,
  CASE WHEN pd_estres_facil<=0.00871 THEN 'G1' WHEN pd_estres_facil<=0.02581 THEN 'G2' WHEN pd_estres_facil<=0.04542 THEN 'G3' WHEN pd_estres_facil<=0.07551 THEN 'G4' WHEN pd_estres_facil<=0.11283 THEN 'G5' WHEN pd_estres_facil<=0.15813 THEN 'G6' ELSE 'GR' END AS grado_estres_facil,
  round(pd_base_cd, 5) AS pd_base_cd,
  CASE WHEN pd_base_cd<=0.00871 THEN 'G1' WHEN pd_base_cd<=0.02581 THEN 'G2' WHEN pd_base_cd<=0.04542 THEN 'G3' WHEN pd_base_cd<=0.07551 THEN 'G4' WHEN pd_base_cd<=0.11283 THEN 'G5' WHEN pd_base_cd<=0.15813 THEN 'G6' ELSE 'GR' END AS grado_base_cd,
  round(pd_estres_cd, 5) AS pd_estres_cd,
  CASE WHEN pd_estres_cd<=0.00871 THEN 'G1' WHEN pd_estres_cd<=0.02581 THEN 'G2' WHEN pd_estres_cd<=0.04542 THEN 'G3' WHEN pd_estres_cd<=0.07551 THEN 'G4' WHEN pd_estres_cd<=0.11283 THEN 'G5' WHEN pd_estres_cd<=0.15813 THEN 'G6' ELSE 'GR' END AS grado_estres_cd
FROM px
