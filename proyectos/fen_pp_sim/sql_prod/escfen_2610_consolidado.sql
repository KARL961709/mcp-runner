-- ============================================================================
-- escfen 2610 consolidado: 3 productos (PP Facil, PP CD, EC) en UNA tabla.
--   Por producto: pd_ttc, pd_pit_freeze, pd_pit, pd_pit_freeze_fen, pd_pit_fen (+ pd_raw compartido). Cada PD con puntuacion.
--   Base: _2610 (freeze, ft set) JOIN _2610_no_freeze (ft vivo oct) 1:1 por key. TTC/pd_raw del freeze (ft-independientes).
--   FEN moderado: shift = 0.77831*ep*(1-0.70*rec_d), gamma=4.2, rec 70%. ep=0.5*max(R/5,0.10)+0.5*max(s,0). Solo sobre PIT (freeze y viva).
--   Geo: reest primario (r_nivel_reest, ubigeo_inei_nodo) + fallback nombre (dist/prov/dep) + s + rec_d. rn DEDUPEADO. Sin gate Pacifico (uso pricing).
-- ============================================================================
CREATE TABLE disc_model_owner.scr_vcadmbnk_final_rsk_cal_2610_escfen
WITH (format = 'PARQUET', write_compression = 'SNAPPY', partitioned_by = ARRAY['codmes']) AS
WITH
g AS (
  SELECT upper(regexp_replace(normalize(trim(departamento), NFD), '\p{M}', '')) AS dep_n,
         upper(regexp_replace(normalize(trim(provincia),    NFD), '\p{M}', '')) AS prov_n,
         upper(regexp_replace(normalize(trim(distrito),     NFD), '\p{M}', '')) AS dist_n,
         cod_ubigeo, r_nivel, pct_expuesto
  FROM d_perm_aws.grado_elnino_ubigeo_v3
),
dist_g AS (
  SELECT dep_n, prov_n, dist_n, MAX(cod_ubigeo) AS cod_ubigeo, CAST(round(AVG(r_nivel)) AS integer) AS r_nivel
  FROM g GROUP BY dep_n, prov_n, dist_n
),
prov_g AS (
  SELECT dep_n, prov_n, substr(MAX(cod_ubigeo),1,4) AS prov_inei4, substr(MAX(cod_ubigeo),1,2) AS dep_inei2,
         SUM(r_nivel*(pct_expuesto+0.001))/SUM(pct_expuesto+0.001) AS r_prov
  FROM g GROUP BY dep_n, prov_n
),
dep_g AS (
  SELECT dep_n, substr(MAX(cod_ubigeo),1,2) AS dep_inei2, SUM(r_nivel*(pct_expuesto+0.001))/SUM(pct_expuesto+0.001) AS r_dep
  FROM g GROUP BY dep_n
),
prov_s AS (SELECT substr(ubigeo,1,4) AS prov_inei4, AVG(s_norm) AS s_prov FROM disc_model_owner.fen_s_indirecto_empleo_2026 GROUP BY substr(ubigeo,1,4)),
dep_s  AS (SELECT substr(ubigeo,1,2) AS dep_inei2,  AVG(s_norm) AS s_dep  FROM disc_model_owner.fen_s_indirecto_empleo_2026 GROUP BY substr(ubigeo,1,2)),
rn AS (
  SELECT key_value, dep_n, prov_n, dist_n FROM (
    SELECT key_value,
      upper(regexp_replace(normalize(trim(dep_ubi_domicilio), NFD), '\p{M}', '')) AS dep_n,
      upper(regexp_replace(normalize(trim(pro_ubi_domicilio), NFD), '\p{M}', '')) AS prov_n,
      upper(regexp_replace(normalize(trim(dis_ubi_domicilio), NFD), '\p{M}', '')) AS dist_n,
      ROW_NUMBER() OVER (PARTITION BY key_value ORDER BY dep_ubi_domicilio) AS rn_d
    FROM e_perm_aws.t_mst_reniec_rsk WHERE tip_doc = '1'
  ) WHERE rn_d = 1
),
base AS (
  SELECT
    f.cod_tip_doc, f.key_value, f.codmes,
    f.pd_raw AS pd_raw,
    f.prob_modelo_ttc_cal_ppfacil AS ttc_ppfacil, f.prob_modelo_ttc_cal_ppcd AS ttc_ppcd, f.prob_modelo_ttc_cal_ec AS ttc_ec,
    f.prob_modelo_cal_ppfacil  AS pitf_ppfacil, f.prob_modelo_cal_ppcd  AS pitf_ppcd, f.prob_modelo_cal_ec  AS pitf_ec,
    nf.prob_modelo_cal_ppfacil AS pit_ppfacil,  nf.prob_modelo_cal_ppcd AS pit_ppcd,  nf.prob_modelo_cal_ec AS pit_ec,
    COALESCE(r.ubigeo_inei_nodo, dd.cod_ubigeo, pg.prov_inei4 || '00', dg.dep_inei2 || '0000', 'SIN_GEO') AS ubigeo,
    COALESCE(substr(r.ubigeo_inei_nodo,1,2), substr(dd.cod_ubigeo,1,2), pg.dep_inei2, dg.dep_inei2, '00') AS dep_inei,
    CAST(COALESCE(CAST(round(r.r_nivel_reest) AS integer), dd.r_nivel,
                  CAST(round(pg.r_prov) AS integer), CAST(round(dg.r_dep) AS integer), 0) AS integer) AS r_reest
  FROM disc_model_owner.scr_vcadmbnk_final_rsk_cal_2610 f
  JOIN disc_model_owner.scr_vcadmbnk_final_rsk_cal_2610_no_freeze nf
    ON f.cod_tip_doc = nf.cod_tip_doc AND f.key_value = nf.key_value
  LEFT JOIN disc_model_owner.mca_bd_reniec_xy_r_reest r ON r.key_value = f.key_value
  LEFT JOIN rn ON rn.key_value = f.key_value
  LEFT JOIN dist_g dd ON r.r_nivel_reest IS NULL AND dd.dep_n = rn.dep_n AND dd.prov_n = rn.prov_n AND dd.dist_n = rn.dist_n
  LEFT JOIN prov_g pg ON r.r_nivel_reest IS NULL AND dd.r_nivel IS NULL AND pg.dep_n = rn.dep_n AND pg.prov_n = rn.prov_n
  LEFT JOIN dep_g  dg ON r.r_nivel_reest IS NULL AND dd.r_nivel IS NULL AND pg.r_prov IS NULL AND dg.dep_n = rn.dep_n
),
enr AS (
  SELECT b.*,
    CASE WHEN b.ubigeo = 'SIN_GEO' THEN 0.0 ELSE COALESCE(s.s_norm, ps.s_prov, ds.s_dep, 1.0) END AS s_norm,
    COALESCE(rd.rec_d, 1.0) AS rec_d
  FROM base b
  LEFT JOIN disc_model_owner.fen_s_indirecto_empleo_2026 s ON s.ubigeo = b.ubigeo
  LEFT JOIN prov_s ps ON ps.prov_inei4 = substr(b.ubigeo,1,4)
  LEFT JOIN dep_s  ds ON ds.dep_inei2  = b.dep_inei
  LEFT JOIN disc_model_owner.fen_recd_2026 rd ON rd.dep_inei = b.dep_inei
),
sh AS (
  SELECT e.*,
    (0.5*greatest(CAST(r_reest AS double)/5.0, 0.10) + 0.5*greatest(s_norm, 0.0)) AS ep,
    0.77831 * (0.5*greatest(CAST(r_reest AS double)/5.0, 0.10) + 0.5*greatest(s_norm, 0.0)) * (1 - 0.70*rec_d) AS shift
  FROM enr e
)
SELECT
  cod_tip_doc, key_value,
  r_reest, ubigeo, dep_inei, round(s_norm,4) AS s_norm, round(rec_d,4) AS rec_d, round(ep,4) AS ep,
  pd_raw, CAST(round(1000*(1 - pd_raw)) AS integer) AS puntuacion_raw,
  -- PPFACIL
  ttc_ppfacil  AS pd_ttc_ppfacil,          CAST(round(1000*(1 - ttc_ppfacil))  AS integer) AS puntuacion_ttc_ppfacil,
  pitf_ppfacil AS pd_pit_freeze_ppfacil,   CAST(round(1000*(1 - pitf_ppfacil)) AS integer) AS puntuacion_pit_freeze_ppfacil,
  pit_ppfacil  AS pd_pit_ppfacil,          CAST(round(1000*(1 - pit_ppfacil))  AS integer) AS puntuacion_pit_ppfacil,
  normal_cdf(0,1, inverse_normal_cdf(0,1, least(greatest(pitf_ppfacil,1e-6),1-1e-6)) + shift) AS pd_pit_freeze_fen_ppfacil,   CAST(round(1000*(1 - normal_cdf(0,1, inverse_normal_cdf(0,1, least(greatest(pitf_ppfacil,1e-6),1-1e-6)) + shift))) AS integer) AS puntuacion_pit_freeze_fen_ppfacil,
  normal_cdf(0,1, inverse_normal_cdf(0,1, least(greatest(pit_ppfacil,1e-6),1-1e-6)) + shift) AS pd_pit_fen_ppfacil,          CAST(round(1000*(1 - normal_cdf(0,1, inverse_normal_cdf(0,1, least(greatest(pit_ppfacil,1e-6),1-1e-6)) + shift))) AS integer) AS puntuacion_pit_fen_ppfacil,
  -- PPCD
  ttc_ppcd  AS pd_ttc_ppcd,          CAST(round(1000*(1 - ttc_ppcd))  AS integer) AS puntuacion_ttc_ppcd,
  pitf_ppcd AS pd_pit_freeze_ppcd,   CAST(round(1000*(1 - pitf_ppcd)) AS integer) AS puntuacion_pit_freeze_ppcd,
  pit_ppcd  AS pd_pit_ppcd,          CAST(round(1000*(1 - pit_ppcd))  AS integer) AS puntuacion_pit_ppcd,
  normal_cdf(0,1, inverse_normal_cdf(0,1, least(greatest(pitf_ppcd,1e-6),1-1e-6)) + shift) AS pd_pit_freeze_fen_ppcd,   CAST(round(1000*(1 - normal_cdf(0,1, inverse_normal_cdf(0,1, least(greatest(pitf_ppcd,1e-6),1-1e-6)) + shift))) AS integer) AS puntuacion_pit_freeze_fen_ppcd,
  normal_cdf(0,1, inverse_normal_cdf(0,1, least(greatest(pit_ppcd,1e-6),1-1e-6)) + shift) AS pd_pit_fen_ppcd,          CAST(round(1000*(1 - normal_cdf(0,1, inverse_normal_cdf(0,1, least(greatest(pit_ppcd,1e-6),1-1e-6)) + shift))) AS integer) AS puntuacion_pit_fen_ppcd,
  -- EC
  ttc_ec  AS pd_ttc_ec,          CAST(round(1000*(1 - ttc_ec))  AS integer) AS puntuacion_ttc_ec,
  pitf_ec AS pd_pit_freeze_ec,   CAST(round(1000*(1 - pitf_ec)) AS integer) AS puntuacion_pit_freeze_ec,
  pit_ec  AS pd_pit_ec,          CAST(round(1000*(1 - pit_ec))  AS integer) AS puntuacion_pit_ec,
  normal_cdf(0,1, inverse_normal_cdf(0,1, least(greatest(pitf_ec,1e-6),1-1e-6)) + shift) AS pd_pit_freeze_fen_ec,   CAST(round(1000*(1 - normal_cdf(0,1, inverse_normal_cdf(0,1, least(greatest(pitf_ec,1e-6),1-1e-6)) + shift))) AS integer) AS puntuacion_pit_freeze_fen_ec,
  normal_cdf(0,1, inverse_normal_cdf(0,1, least(greatest(pit_ec,1e-6),1-1e-6)) + shift) AS pd_pit_fen_ec,          CAST(round(1000*(1 - normal_cdf(0,1, inverse_normal_cdf(0,1, least(greatest(pit_ec,1e-6),1-1e-6)) + shift))) AS integer) AS puntuacion_pit_fen_ec,
  codmes
FROM sh
