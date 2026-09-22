-- e10_sim_celdas_202609.sql | CTAS agregado para el simulador FEN de la campana PP 202609.
-- Crea disc_model_owner.fen_pp_sim_celdas_202609 (PARQUET, tabla gestionada; el export lo aplica el usuario).
-- GRANO = ubigeo x geo_src x r_reest x grado_PIT. Coherente por grupo (suma exacto a grado, R, depto, grupo FEN).
--
-- TODO CLIENTE QUEDA GATEADO. R por 4 tiers (geo_src marca por donde entro):
--   'reest'     : R per-persona reestructurado (mca_bd_reniec_xy_r_reest), geolocalizado, distrito preciso.
--   'decl_dist' : sin reest -> domicilio declarado RENIEC (e_perm_aws.t_mst_reniec_rsk, nombre dep+prov+dist)
--                 -> grado_elnino_ubigeo_v3 por NOMBRE -> R a nivel DISTRITO (patron enr_stock_pp / rd_altas_pp).
--   'decl_prov' : si el distrito no matchea por nombre -> grado agregado a provincia (r_nivel ponderado por pct_expuesto).
--   'decl_dep'  : red de seguridad -> grado agregado a departamento.
--   'none'      : sin domicilio declarado -> pac=0, sin overlay.
-- Join por NOMBRE (normalize NFD + strip acentos) para esquivar la trampa INEI<>RENIEC (Piura->Puno).
-- s (indirecto): distrito exacto (reest / decl_dist) / promedio provincia / promedio depto / 0.
-- rec_d (recuperacion inflacion, departamental) se aplica en el artifact via dep_inei.
--
-- Puente e08: substr(subject_id,3)=key_value. Solo agregados salen.
-- Mapeo verificado: pd_raw=pd_raw, pd_ttc=prob_modelo_ttc_cal_ppfacil, pd_pit=prob_modelo_cal_ppfacil,
--   grado=puntuacion_modelo_cal_ppfacil vs 985/955/947/912/892/864.
-- Correr:  .\Go.ps1 -SqlDir proyectos/fen_pp_sim/sql_prod -Only e10_sim_celdas_202609   (rebuild: -Only e10b_drop_sim_celdas)
CREATE TABLE disc_model_owner.fen_pp_sim_celdas_202609
WITH (format = 'PARQUET') AS
WITH camp AS (
  SELECT DISTINCT substr(subject_id, 3) AS kv
  FROM d_perm_aws.t_edc_ar_camp_vars_sep2qrec_temp
  WHERE p_codmes = '202609' AND producto = 'PP' AND sub_producto = 'PP' AND num_carga = '2.1 Rec'
),
g AS (
  SELECT upper(regexp_replace(normalize(trim(departamento), NFD), '\p{M}', '')) AS dep_n,
         upper(regexp_replace(normalize(trim(provincia),    NFD), '\p{M}', '')) AS prov_n,
         upper(regexp_replace(normalize(trim(distrito),     NFD), '\p{M}', '')) AS dist_n,
         cod_ubigeo, r_nivel, pacifico, pct_expuesto
  FROM disc_model_owner.grado_elnino_ubigeo_v3
),
dist_g AS (
  SELECT dep_n, prov_n, dist_n, MAX(cod_ubigeo) AS cod_ubigeo,
         CAST(round(AVG(r_nivel)) AS integer) AS r_nivel, MAX(pacifico) AS pac
  FROM g GROUP BY dep_n, prov_n, dist_n
),
prov_g AS (
  SELECT dep_n, prov_n, substr(MAX(cod_ubigeo),1,4) AS prov_inei4, substr(MAX(cod_ubigeo),1,2) AS dep_inei2,
         SUM(r_nivel*(pct_expuesto+0.001))/SUM(pct_expuesto+0.001) AS r_prov, MAX(pacifico) AS pac
  FROM g GROUP BY dep_n, prov_n
),
dep_g AS (
  SELECT dep_n, substr(MAX(cod_ubigeo),1,2) AS dep_inei2,
         SUM(r_nivel*(pct_expuesto+0.001))/SUM(pct_expuesto+0.001) AS r_dep, MAX(pacifico) AS pac
  FROM g GROUP BY dep_n
),
prov_s AS (SELECT substr(ubigeo,1,4) AS prov_inei4, AVG(s_total) AS s_prov FROM disc_model_owner.fen_s_indirecto GROUP BY substr(ubigeo,1,4)),
dep_s  AS (SELECT substr(ubigeo,1,2) AS dep_inei2,  AVG(s_total) AS s_dep  FROM disc_model_owner.fen_s_indirecto GROUP BY substr(ubigeo,1,2)),
rn AS (
  SELECT key_value,
         upper(regexp_replace(normalize(trim(dep_ubi_domicilio), NFD), '\p{M}', '')) AS dep_n,
         upper(regexp_replace(normalize(trim(pro_ubi_domicilio), NFD), '\p{M}', '')) AS prov_n,
         upper(regexp_replace(normalize(trim(dis_ubi_domicilio), NFD), '\p{M}', '')) AS dist_n
  FROM e_perm_aws.t_mst_reniec_rsk WHERE tip_doc = '1'
)
SELECT
  COALESCE(r.ubigeo_inei_nodo, dd.cod_ubigeo, pg.prov_inei4 || '00', dg.dep_inei2 || '0000', 'SIN_GEO') AS ubigeo,
  COALESCE(substr(r.ubigeo_inei_nodo,1,2), substr(dd.cod_ubigeo,1,2), pg.dep_inei2, dg.dep_inei2, '00')  AS dep_inei,
  CASE WHEN r.r_nivel_reest IS NOT NULL THEN 'reest'
       WHEN dd.r_nivel IS NOT NULL      THEN 'decl_dist'
       WHEN pg.r_prov  IS NOT NULL      THEN 'decl_prov'
       WHEN dg.r_dep   IS NOT NULL      THEN 'decl_dep'
       ELSE 'none' END AS geo_src,
  CAST(COALESCE(CAST(round(r.r_nivel_reest) AS integer), dd.r_nivel,
                CAST(round(pg.r_prov) AS integer), CAST(round(dg.r_dep) AS integer), 0) AS varchar) AS r_reest,
  CASE
    WHEN u.puntuacion_modelo_cal_ppfacil >= 985 THEN 'G1'
    WHEN u.puntuacion_modelo_cal_ppfacil >= 955 THEN 'G2'
    WHEN u.puntuacion_modelo_cal_ppfacil >= 947 THEN 'G3'
    WHEN u.puntuacion_modelo_cal_ppfacil >= 912 THEN 'G4'
    WHEN u.puntuacion_modelo_cal_ppfacil >= 892 THEN 'G5'
    WHEN u.puntuacion_modelo_cal_ppfacil >= 864 THEN 'G6'
    ELSE 'GR'
  END AS grado_pit,
  COUNT(*) AS n,
  MAX(COALESCE(CASE WHEN r.r_nivel_reest IS NOT NULL THEN (CASE WHEN r.r_nivel_reest>=1 THEN 1 ELSE 0 END) END,
               CASE WHEN dd.r_nivel IS NOT NULL THEN dd.pac END, pg.pac, dg.pac, 0)) AS pac,
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
LEFT JOIN rn      ON rn.key_value = c.kv
LEFT JOIN dist_g dd ON r.r_nivel_reest IS NULL AND dd.dep_n = rn.dep_n AND dd.prov_n = rn.prov_n AND dd.dist_n = rn.dist_n
LEFT JOIN prov_g pg ON r.r_nivel_reest IS NULL AND dd.r_nivel IS NULL AND pg.dep_n = rn.dep_n AND pg.prov_n = rn.prov_n
LEFT JOIN dep_g  dg ON r.r_nivel_reest IS NULL AND dd.r_nivel IS NULL AND pg.r_prov IS NULL AND dg.dep_n = rn.dep_n
LEFT JOIN disc_model_owner.fen_s_indirecto s ON s.ubigeo = COALESCE(r.ubigeo_inei_nodo, dd.cod_ubigeo)
LEFT JOIN prov_s ps ON ps.prov_inei4 = pg.prov_inei4
LEFT JOIN dep_s  ds ON ds.dep_inei2  = COALESCE(pg.dep_inei2, dg.dep_inei2)
GROUP BY 1, 2, 3, 4, 5
