-- scr_cal_v_v2overlap.sql | VALIDA que la cadena V2 rebuilt reproduce el bankbn. Sobre 202601-607 (flg_match_v2=1) recomputa la rebuilt desde probabilidad+tip_doc+fhat y la compara vs pd_opt_v2 almacenado (join oficial). max|dif| ~ 0 confirma que la rebuilt es fiel, por lo tanto 202608 (flg=2) es confiable. Agregado.
WITH fh2(cm,fhv) AS (VALUES
  (202501, 1.5193331146887308),
  (202502, 1.5295598659038827),
  (202503, 1.5467370500137263),
  (202504, 1.6703824334712063),
  (202505, 1.8720398724011265),
  (202506, 2.0194314436566057),
  (202507, 2.0194314436566057),
  (202508, 2.0194314436566057),
  (202509, 2.0194314436566057),
  (202510, 2.0194314436566057),
  (202511, 2.0194314436566057),
  (202512, 2.0194314436566057),
  (202601, 2.0194314436566057),
  (202602, 2.0194314436566057),
  (202603, 2.0194314436566057),
  (202604, 1.9724204666385832),
  (202605, 1.471558584190937),
  (202606, 0.8175440736248093),
  (202607, 0.20088867265642565),
  (202608, -0.0213840458600021)
),
r0 AS (
  SELECT p_codmes, tip_doc, pd_opt_v2 AS stored,
    GREATEST(1e-6, LEAST(1-1e-6, TRY_CAST(probabilidad AS DOUBLE))) AS pcv2,
    fh2.fhv AS fhat_v2
  FROM disc_model_owner.b46029_scr_admbankbpe_cal_202608 t
  LEFT JOIN fh2 ON fh2.cm = CAST(t.p_codmes AS INT)
  WHERE t.p_codmes BETWEEN '202601' AND '202607' AND t.flg_match_v2 = 1
),
r1 AS (
  SELECT r0.*,
    GREATEST(1e-6, LEAST(1-1e-6, CASE WHEN tip_doc='2'
      THEN 1.0/(1.0+exp(-(-0.15993259962662906+0.9675398918720501*(ln(pcv2)-ln(1-pcv2)))))
      ELSE 1.0/(1.0+exp(-(-0.6601884802657757+0.5938923689532265*ln(pcv2)+0.10766439295961687*ln(1-pcv2)))) END)) AS pd_cal_v2
  FROM r0
),
r2 AS (
  SELECT r1.*,
    GREATEST(0.001, LEAST(0.999,
      0.035978817268325414*(0.03*((1-exp(-35*pd_cal_v2))/(1-exp(-35.0)))+0.16*(1-((1-exp(-35*pd_cal_v2))/(1-exp(-35.0)))))
      /(CASE WHEN tip_doc='1' THEN 0.03424207361820211 ELSE 0.03868433725325406 END))) AS rho_i2
  FROM r1
),
r3 AS (
  SELECT r2.*,
    normal_cdf(0.0,1.0,(inverse_normal_cdf(0.0,1.0,pd_cal_v2)-sqrt(rho_i2)*0.34999999999999998*fhat_v2)/sqrt(1-rho_i2)) AS pit_v2
  FROM r2
),
r4 AS (
  SELECT r3.*,
    GREATEST(1e-6, LEAST(1-1e-6, GREATEST(1e-6, LEAST(1-1e-6, pit_v2*(CASE WHEN tip_doc='1' THEN 1.16299104583772395 ELSE 1.13685059874822714 END)))*(CASE WHEN tip_doc='2' THEN 0.68140 ELSE 0.96970 END))) AS rebuilt
  FROM r3
)
SELECT p_codmes,
  COUNT(*) AS n,
  ROUND(AVG(ABS(stored-rebuilt)),10) AS mad,
  ROUND(MAX(ABS(stored-rebuilt)),10) AS maxad,
  ROUND(100*AVG(stored),5) AS avg_stored_pct,
  ROUND(100*AVG(rebuilt),5) AS avg_rebuilt_pct
FROM r4 GROUP BY p_codmes ORDER BY p_codmes
