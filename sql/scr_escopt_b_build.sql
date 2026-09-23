-- scr_escopt_b_build.sql | V2 ESCENARIO OPTIMISTA (pd_v2_esc_opt) ultimos 3 meses p_codmes 202607-202609 (actualizado desde fuentes madre; 202609 ya cargo en scr_admbankbpe_rsk). Cadena lineage-A: COALESCE(bankbn oficial scr_admbankbpe_calibrado_202607 x factor esc_opt, rebuilt logit/beta + rho Basel + Vasicek fhat + re-ancla x factor). 202607 bankbn (flg=1), 202608/202609 rebuilt (flg=2, bankbn _202607 no llega ahi). fhat_v2 de ft_mensual.csv (contrato V2). NO usa la correccion del cruce ni el DSM (V2 oficial, personeria por tip_doc). Espeja scr_cal_b5.
CREATE TABLE disc_model_owner.b46029_escopt_3m_202609
WITH (format='PARQUET', parquet_compression='SNAPPY', partitioned_by=ARRAY['p_codmes']) AS
WITH fh2(cm,fhv) AS (VALUES
  (202607, 0.20088867265642565),
  (202608, -0.0213840458600021),
  (202609, -0.03459445072099439)
),
v2 AS (
  SELECT CAST(p_codmes AS INT) AS p_codmes, tip_doc, key_value, prob_modelo_cal,
         ROW_NUMBER() OVER (PARTITION BY p_codmes, tip_doc, key_value ORDER BY fec_replica DESC) AS rn
  FROM disc_model_owner.scr_admbankbpe_calibrado_202607
  WHERE p_codmes BETWEEN '202607' AND '202609'
),
b AS (
  SELECT CAST(s.p_codmes AS INT) AS p_codmes_i, s.p_codmes, s.tip_doc, s.key_value,
    TRY_CAST(s.probabilidad AS DOUBLE) AS probabilidad,
    GREATEST(1e-6, LEAST(1-1e-6, TRY_CAST(s.probabilidad AS DOUBLE))) AS pcv2,
    v2.prob_modelo_cal AS v2cal
  FROM e_perm_aws.scr_admbankbpe_rsk s
  LEFT JOIN v2 ON v2.tip_doc = s.tip_doc AND v2.key_value = s.key_value AND v2.p_codmes = CAST(s.p_codmes AS INT) AND v2.rn = 1
  WHERE s.modelo = 'ADMBANKBPE' AND s.probabilidad IS NOT NULL AND s.p_codmes BETWEEN '202607' AND '202609'
),
d AS (SELECT b.*, fh2.fhv AS fhat_v2 FROM b LEFT JOIN fh2 ON fh2.cm = b.p_codmes_i),
g AS (
  SELECT d.*,
    GREATEST(1e-6, LEAST(1-1e-6, CASE WHEN tip_doc='2'
      THEN 1.0/(1.0+exp(-(-0.15993259962662906+0.9675398918720501*(ln(pcv2)-ln(1-pcv2)))))
      ELSE 1.0/(1.0+exp(-(-0.6601884802657757+0.5938923689532265*ln(pcv2)+0.10766439295961687*ln(1-pcv2)))) END)) AS pd_cal_v2
  FROM d
),
h AS (
  SELECT g.*,
    GREATEST(0.001, LEAST(0.999,
      0.035978817268325414*(0.03*((1-exp(-35*pd_cal_v2))/(1-exp(-35.0)))+0.16*(1-((1-exp(-35*pd_cal_v2))/(1-exp(-35.0)))))
      /(CASE WHEN tip_doc='1' THEN 0.03424207361820211 ELSE 0.03868433725325406 END))) AS rho_i2
  FROM g
),
x AS (
  SELECT h.*,
    normal_cdf(0.0,1.0,(inverse_normal_cdf(0.0,1.0,pd_cal_v2)-sqrt(rho_i2)*0.34999999999999998*fhat_v2)/sqrt(1-rho_i2)) AS pit_v2
  FROM h
),
fin AS (
  SELECT x.*,
    CASE WHEN x.v2cal IS NOT NULL THEN greatest(1e-6, least(1-1e-6, x.v2cal * CASE WHEN x.tip_doc='2' THEN 0.68140 ELSE 0.96970 END))
         WHEN x.fhat_v2 IS NOT NULL THEN greatest(1e-6, least(1-1e-6, greatest(1e-6, least(1-1e-6, x.pit_v2*(CASE WHEN x.tip_doc='1' THEN 1.16299104583772395 ELSE 1.13685059874822714 END)))*(CASE WHEN x.tip_doc='2' THEN 0.68140 ELSE 0.96970 END)))
         ELSE NULL END AS pd_v2_esc_opt,
    CASE WHEN x.v2cal IS NOT NULL THEN 1 WHEN x.fhat_v2 IS NOT NULL THEN 2 ELSE 0 END AS flg_match_v2
  FROM x
)
SELECT
  f.tip_doc,
  f.key_value,
  f.probabilidad,
  f.pd_v2_esc_opt,
  CAST(round((1.0-f.pd_v2_esc_opt)*1000) AS INTEGER) AS puntuacion_v2,
  CASE WHEN 1.0-round((1.0-f.pd_v2_esc_opt)*1000)/1000.0 <= 0.0345 THEN 'Bajo'
       WHEN 1.0-round((1.0-f.pd_v2_esc_opt)*1000)/1000.0 <= 0.0575 THEN 'Medio Bajo'
       WHEN 1.0-round((1.0-f.pd_v2_esc_opt)*1000)/1000.0 <= 0.0785 THEN 'Medio'
       WHEN 1.0-round((1.0-f.pd_v2_esc_opt)*1000)/1000.0 <= 0.1295 THEN 'Medio Alto'
       ELSE 'Alto' END AS grupos_ant,
  f.flg_match_v2,
  f.p_codmes
FROM fin f
