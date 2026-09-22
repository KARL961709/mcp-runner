-- e10_sim_celdas_202609.sql | CTAS agregado para el simulador FEN de la campana PP 202609.
-- Crea disc_model_owner.fen_pp_sim_celdas_202609 (PARQUET, tabla gestionada, sin ruta S3 externa; el export lo aplica el usuario).
-- GRANO = ubigeo x geo_src x r_reest x grado_PIT. Coherente por grupo (suma exacto a grado, R, depto, grupo FEN).
--
-- TODO CLIENTE QUEDA GATEADO (3 tiers de R, columna geo_src marca por donde entro cada quien):
--   tier 'reest' (89.7%): R per-persona reestructurado (mca_bd_reniec_xy_r_reest), preciso a nivel distrito.
--   tier 'prov'  (~10%): sin reest -> grado_elnino_ubigeo_v3 agregado a PROVINCIA (r_nivel ponderado por pct_expuesto),
--                        unido por NOMBRE dep+prov normalizado NFD (e12: la campana trae ubigeo_dep/prov como NOMBRE,
--                        no codigo -> join por nombre esquiva la trampa INEI<>RENIEC, patron de rd_altas_pp).
--   tier 'dep'   (residual): red de seguridad, mismo grado agregado a DEPARTAMENTO por nombre.
--   tier 'none'  (sin geografia): pac=0, sin overlay.
-- s (indirecto) por tier: distrito exacto (reest) / promedio provincia / promedio depto / 0.
-- rec_d (recuperacion inflacion, departamental) se aplica en el artifact via dep_inei.
--
-- Puente e08: substr(subject_id,3)=key_value. Campana deduplicada por llave. Solo agregados salen.
-- Mapeo verificado (scr_vcadmbnk_final_rsk_cal_2609): pd_raw=pd_raw, pd_ttc=prob_modelo_ttc_cal_ppfacil,
--   pd_pit=prob_modelo_cal_ppfacil, grado=puntuacion_modelo_cal_ppfacil vs 985/955/947/912/892/864.
--
-- Correr de a uno:  .\Go.ps1 -SqlDir proyectos/fen_pp_sim/sql_prod -Only e10_sim_celdas_202609
-- RE-crear: -Only e10b_drop_sim_celdas  (tabla gestionada: el DROP limpia datos y metadata, sin paso manual en S3)
CREATE TABLE disc_model_owner.fen_pp_sim_celdas_202609
WITH (format = 'PARQUET') AS
WITH camp AS (
  SELECT substr(subject_id, 3) AS kv,
         upper(regexp_replace(normalize(trim(MAX(ubigeo_dep)),  NFD), '\p{M}', '')) AS dep_n,
         upper(regexp_replace(normalize(trim(MAX(ubigeo_prov)), NFD), '\p{M}', '')) AS prov_n
  FROM d_perm_aws.t_edc_ar_camp_vars_sep2qrec_temp
  WHERE p_codmes = '202609' AND producto = 'PP' AND sub_producto = 'PP' AND num_carga = '2.1 Rec'
  GROUP BY substr(subject_id, 3)
),
prov_g AS (
  SELECT upper(regexp_replace(normalize(trim(departamento), NFD), '\p{M}', '')) AS dep_n,
         upper(regexp_replace(normalize(trim(provincia),    NFD), '\p{M}', '')) AS prov_n,
         substr(MAX(cod_ubigeo), 1, 4) AS prov_inei4,
         substr(MAX(cod_ubigeo), 1, 2) AS dep_inei2,
         SUM(r_nivel * (pct_expuesto + 0.001)) / SUM(pct_expuesto + 0.001) AS r_prov,
         MAX(pacifico) AS pac_prov
  FROM disc_model_owner.grado_elnino_ubigeo_v3
  GROUP BY 1, 2
),
dep_g AS (
  SELECT upper(regexp_replace(normalize(trim(departamento), NFD), '\p{M}', '')) AS dep_n,
         substr(MAX(cod_ubigeo), 1, 2) AS dep_inei2,
         SUM(r_nivel * (pct_expuesto + 0.001)) / SUM(pct_expuesto + 0.001) AS r_dep,
         MAX(pacifico) AS pac_dep
  FROM disc_model_owner.grado_elnino_ubigeo_v3
  GROUP BY 1
),
prov_s AS (
  SELECT substr(ubigeo, 1, 4) AS prov_inei4, AVG(s_total) AS s_prov
  FROM disc_model_owner.fen_s_indirecto GROUP BY substr(ubigeo, 1, 4)
),
dep_s AS (
  SELECT substr(ubigeo, 1, 2) AS dep_inei2, AVG(s_total) AS s_dep
  FROM disc_model_owner.fen_s_indirecto GROUP BY substr(ubigeo, 1, 2)
)
SELECT
  CASE WHEN r.r_nivel_reest IS NOT NULL THEN r.ubigeo_inei_nodo
       WHEN pg.r_prov IS NOT NULL       THEN pg.prov_inei4 || '00'
       WHEN dg.r_dep  IS NOT NULL       THEN dg.dep_inei2 || '0000'
       ELSE 'SIN_GEO' END AS ubigeo,
  CASE WHEN r.r_nivel_reest IS NOT NULL THEN substr(r.ubigeo_inei_nodo, 1, 2)
       WHEN pg.r_prov IS NOT NULL       THEN pg.dep_inei2
       WHEN dg.r_dep  IS NOT NULL       THEN dg.dep_inei2
       ELSE '00' END AS dep_inei,
  CASE WHEN r.r_nivel_reest IS NOT NULL THEN 'reest'
       WHEN pg.r_prov IS NOT NULL       THEN 'prov'
       WHEN dg.r_dep  IS NOT NULL       THEN 'dep'
       ELSE 'none' END AS geo_src,
  CAST(COALESCE(CAST(round(r.r_nivel_reest) AS integer),
                CAST(round(pg.r_prov)       AS integer),
                CAST(round(dg.r_dep)        AS integer), 0) AS varchar) AS r_reest,
  CASE
    WHEN u.puntuacion_modelo_cal_ppfacil >= 985 THEN 'G1'
    WHEN u.puntuacion_modelo_cal_ppfacil >= 955 THEN 'G2'
    WHEN u.puntuacion_modelo_cal_ppfacil >= 947 THEN 'G3'
    WHEN u.puntuacion_modelo_cal_ppfacil >= 912 THEN 'G4'
    WHEN u.puntuacion_modelo_cal_ppfacil >= 892 THEN 'G5'
    WHEN u.puntuacion_modelo_cal_ppfacil >= 864 THEN 'G6'
    ELSE 'GR'
  END AS grado_pit,
  COUNT(*)                                              AS n,
  MAX(CASE WHEN r.r_nivel_reest IS NOT NULL THEN (CASE WHEN r.r_nivel_reest >= 1 THEN 1 ELSE 0 END)
           WHEN pg.r_prov IS NOT NULL       THEN pg.pac_prov
           WHEN dg.r_dep  IS NOT NULL       THEN dg.pac_dep
           ELSE 0 END)                                  AS pac,
  AVG(u.pd_raw)                                         AS pd_raw,
  AVG(u.prob_modelo_ttc_cal_ppfacil)                   AS pd_ttc,
  AVG(u.prob_modelo_cal_ppfacil)                       AS pd_pit,
  AVG(CAST(u.puntuacion_modelo_cal_ppfacil AS double)) AS score_avg,
  AVG(COALESCE(s.s_total, ps.s_prov, ds.s_dep, 0))     AS s_avg,
  AVG(r.exp25)                                         AS exp25_avg,
  AVG(r.exp50)                                         AS exp50_avg,
  MIN(u.prob_modelo_cal_ppfacil)                       AS pd_pit_min,
  MAX(u.prob_modelo_cal_ppfacil)                       AS pd_pit_max
FROM camp c
JOIN      d_perm_aws.scr_vcadmbnk_final_rsk_cal_2609 u ON u.key_value = c.kv
LEFT JOIN disc_model_owner.mca_bd_reniec_xy_r_reest  r ON r.key_value = c.kv
LEFT JOIN prov_g pg ON pg.dep_n = c.dep_n AND pg.prov_n = c.prov_n
LEFT JOIN dep_g  dg ON dg.dep_n = c.dep_n
LEFT JOIN prov_s ps ON ps.prov_inei4 = pg.prov_inei4
LEFT JOIN dep_s  ds ON ds.dep_inei2 = COALESCE(pg.dep_inei2, dg.dep_inei2)
LEFT JOIN disc_model_owner.fen_s_indirecto s ON s.ubigeo = r.ubigeo_inei_nodo
GROUP BY 1, 2, 3, 4, 5
