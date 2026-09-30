-- e25_scr_escfen_full_2609.sql | TABLA MAESTRA de PD por escenario y cliente, UNIVERSO COMPLETO.
-- Identica al e23 salvo que arranca de TODA la d_perm_aws.scr_vcadmbnk_final_rsk_cal_2609 (SIN filtro de campana).
-- Crea disc_model_owner.scr_vcadmbnk_final_rsk_cal_2609_escfen (PARQUET, tabla gestionada).
-- REQUISITO: la fuente debe ser 1 fila por key_value (correr e24_check_grain_scr2609 antes; si no, arranque directo DUPLICA).
-- Escenarios (per-cliente, no re-calibra; lee pd_raw/ttc/pit/puntuaciones/ft_macro ya desplegados):
--   esc1 = pit base (sin FEN)                                     = prob_modelo_cal_ppfacil
--   esc2 = pit + FEN(gamma=4.2) + recuperacion 70%
--   esc3 = pit + macro PESIMISTA (IPC 5.34%, I-2027 pico), sin FEN
--   esc4 = pit + macro PESIMISTA + FEN(gamma=4.2) + recuperacion 50%
-- FEN:  shift_probit = LG*ep*(1-wrec*rec_d), ep=0.5*max(R/5,0.10)+0.5*max(s_norm,0), LG=0.185*4.2=0.77831.
-- MACRO: shift_probit = (ft_pes - ft_macro_ppfacil)/sqrt(1-rho), ft_pes=0.15778, sqrt(1-rho)=0.98326.
-- Puntuacion = (1 - PD) * 1000 (exacta). Cruce ubigeo INEI = igual e10/e23.
-- Correr:  .\Go.ps1 -SqlDir proyectos/fen_pp_sim/sql_prod -Only e25_scr_escfen_full_2609   (rebuild: -Only e25b_drop_escfen antes)
CREATE TABLE disc_model_owner.scr_vcadmbnk_final_rsk_cal_2609_escfen
WITH (format = 'PARQUET') AS
WITH g AS (
  SELECT upper(regexp_replace(normalize(trim(departamento), NFD), '\p{M}', '')) AS dep_n,
         upper(regexp_replace(normalize(trim(provincia),    NFD), '\p{M}', '')) AS prov_n,
         upper(regexp_replace(normalize(trim(distrito),     NFD), '\p{M}', '')) AS dist_n,
         cod_ubigeo, r_nivel, pacifico, pct_expuesto
  FROM d_perm_aws.grado_elnino_ubigeo_v3
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
prov_s AS (SELECT substr(ubigeo,1,4) AS prov_inei4, AVG(s_norm) AS s_prov FROM disc_model_owner.fen_s_indirecto_empleo_2026 GROUP BY substr(ubigeo,1,4)),
dep_s  AS (SELECT substr(ubigeo,1,2) AS dep_inei2,  AVG(s_norm) AS s_dep  FROM disc_model_owner.fen_s_indirecto_empleo_2026 GROUP BY substr(ubigeo,1,2)),
rn AS (
  SELECT key_value,
         upper(regexp_replace(normalize(trim(dep_ubi_domicilio), NFD), '\p{M}', '')) AS dep_n,
         upper(regexp_replace(normalize(trim(pro_ubi_domicilio), NFD), '\p{M}', '')) AS prov_n,
         upper(regexp_replace(normalize(trim(dis_ubi_domicilio), NFD), '\p{M}', '')) AS dist_n
  FROM e_perm_aws.t_mst_reniec_rsk WHERE tip_doc = '1'
),
base AS (
  SELECT
    u.key_value AS key_value,
    COALESCE(r.ubigeo_inei_nodo, dd.cod_ubigeo, pg.prov_inei4 || '00', dg.dep_inei2 || '0000', 'SIN_GEO') AS ubigeo,
    COALESCE(substr(r.ubigeo_inei_nodo,1,2), substr(dd.cod_ubigeo,1,2), pg.dep_inei2, dg.dep_inei2, '00') AS dep_inei,
    CAST(COALESCE(CAST(round(r.r_nivel_reest) AS integer), dd.r_nivel,
                  CAST(round(pg.r_prov) AS integer), CAST(round(dg.r_dep) AS integer), 0) AS integer) AS r_reest,
    u.pd_raw AS pd_raw,
    u.prob_modelo_ttc_cal_ppfacil AS pd_ttc,
    u.prob_modelo_cal_ppfacil AS pit,
    CAST(u.puntuacion_modelo_cal_ppfacil AS double) AS punt_pit,
    CAST(u.puntuacion_modelo_ttc_cal_ppfacil AS double) AS punt_ttc,
    u.ft_macro_ppfacil AS ft_base
  FROM d_perm_aws.scr_vcadmbnk_final_rsk_cal_2609 u
  LEFT JOIN disc_model_owner.mca_bd_reniec_xy_r_reest  r ON r.key_value = u.key_value
  LEFT JOIN rn      ON rn.key_value = u.key_value
  LEFT JOIN dist_g dd ON r.r_nivel_reest IS NULL AND dd.dep_n = rn.dep_n AND dd.prov_n = rn.prov_n AND dd.dist_n = rn.dist_n
  LEFT JOIN prov_g pg ON r.r_nivel_reest IS NULL AND dd.r_nivel IS NULL AND pg.dep_n = rn.dep_n AND pg.prov_n = rn.prov_n
  LEFT JOIN dep_g  dg ON r.r_nivel_reest IS NULL AND dd.r_nivel IS NULL AND pg.r_prov IS NULL AND dg.dep_n = rn.dep_n
),
enr AS (
  SELECT b.*,
    CASE WHEN b.ubigeo = 'SIN_GEO' THEN 0.0
         ELSE COALESCE(s.s_norm, ps.s_prov, ds.s_dep, 1.0) END AS s_norm,
    COALESCE(rd.rec_d, 1.0) AS rec_d
  FROM base b
  LEFT JOIN disc_model_owner.fen_s_indirecto_empleo_2026 s ON s.ubigeo = b.ubigeo
  LEFT JOIN prov_s ps ON ps.prov_inei4 = substr(b.ubigeo,1,4)
  LEFT JOIN dep_s  ds ON ds.dep_inei2  = b.dep_inei
  LEFT JOIN disc_model_owner.fen_recd_2026 rd ON rd.dep_inei = b.dep_inei
),
sh AS (
  SELECT e.*,
    (0.5*greatest(CAST(r_reest AS double)/5.0, 0.10) + 0.5*greatest(s_norm,0.0)) AS ep,
    inverse_normal_cdf(0,1, least(greatest(pit,1e-4),0.999)) AS z_pit,
    (0.15778 - COALESCE(ft_base,0.10027))/0.98326 AS macro
  FROM enr e
),
sh2 AS (
  SELECT s.*,
    normal_cdf(0,1, z_pit + 0.77831*ep*(1-0.70*rec_d))         AS pd_esc2,
    normal_cdf(0,1, z_pit + macro)                          AS pd_esc3,
    normal_cdf(0,1, z_pit + macro + 0.77831*ep*(1-0.50*rec_d)) AS pd_esc4
  FROM sh s
)
SELECT
  key_value, r_reest, ubigeo, dep_inei, round(s_norm,4) AS s_norm, rec_d, round(macro,5) AS macro_shift,
  pd_raw, pd_ttc,
  pit      AS pd_esc1_base,
  pd_esc2  AS pd_esc2_fen70,
  pd_esc3  AS pd_esc3_macropes,
  pd_esc4  AS pd_esc4_macropes_fen50,
  CAST(punt_pit AS integer)                          AS punt_esc1_base,
  CAST(punt_ttc AS integer)                          AS punt_ttc,
  CAST(round((1 - pd_raw ) * 1000) AS integer)       AS punt_raw,
  CAST(round((1 - pd_esc2) * 1000) AS integer)       AS punt_esc2_fen70,
  CAST(round((1 - pd_esc3) * 1000) AS integer)       AS punt_esc3_macropes,
  CAST(round((1 - pd_esc4) * 1000) AS integer)       AS punt_esc4_macropes_fen50
FROM sh2
