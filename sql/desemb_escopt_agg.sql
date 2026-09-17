-- desemb_escopt_agg.sql | AGREGADO del escenario optimo sobre desembolsos (read-only, sale a _resultados.txt, SIN -Bajar).
--   Universo = nuestros 5 productos (ex IMPULSO/GARANTIAS/BONO BUEN PAGADOR/FONDO CRECER), solo clientes con score bankbn (flg_match=1).
--   pd_esc_opt = prob_modelo_cal x factor personeria (PJJ 0.68140 / PNN 0.96970). Cruce (tip_doc,key_value,p_codmes=cod_mes), scr dedup fec_replica.
--   Devuelve DOS lecturas: (1) por PERSONERIA sobre maduras, (2) por COD_MES (linea del escenario optimo para el evolutivo).
--   Correr:  .\Go.ps1 -Only desemb_escopt_agg
WITH s AS (
  SELECT CAST(p_codmes AS INTEGER) AS p_codmes, tip_doc, key_value,
         prob_modelo_cal,
         ROW_NUMBER() OVER (PARTITION BY p_codmes, tip_doc, key_value ORDER BY fec_replica DESC) AS rn
  FROM disc_model_owner.scr_admbankbpe_calibrado_202607
),
j AS (
  SELECT d.cod_mes, d.cod_tip_doc, d.meses_madurez, d.target_12m,
         GREATEST(1e-6, LEAST(1 - 1e-6,
           s.prob_modelo_cal * CASE WHEN d.cod_tip_doc = '2' THEN 0.68140 ELSE 0.96970 END)) AS pd_esc_opt
  FROM disc_model_owner.b46029_desemb_cal_202609 d
  JOIN s ON s.tip_doc = d.cod_tip_doc AND s.key_value = d.key_value AND s.p_codmes = d.cod_mes AND s.rn = 1
  WHERE d.desc_producto NOT IN ('IMPULSO','GARANTIAS','BONO BUEN PAGADOR','FONDO CRECER')
    AND d.pd_raw IS NOT NULL
)
SELECT 'POR_PERSONERIA' AS bloque,
       CASE WHEN cod_tip_doc = '2' THEN 'PJ' ELSE 'PN' END AS k,
       COUNT(*) AS n,
       COUNT(CASE WHEN meses_madurez = 12 THEN 1 END) AS n_mad,
       ROUND(100 * AVG(CASE WHEN meses_madurez = 12 THEN pd_esc_opt END), 2) AS pd_escopt_pct,
       ROUND(100 * AVG(CASE WHEN meses_madurez = 12 THEN target_12m END), 2) AS rd12_pct
FROM j GROUP BY 1, 2
UNION ALL
SELECT 'POR_PERSONERIA', 'TOTAL', COUNT(*), COUNT(CASE WHEN meses_madurez = 12 THEN 1 END),
       ROUND(100 * AVG(CASE WHEN meses_madurez = 12 THEN pd_esc_opt END), 2),
       ROUND(100 * AVG(CASE WHEN meses_madurez = 12 THEN target_12m END), 2)
FROM j
ORDER BY 1, 2;

-- (2) linea por mes para el evolutivo
WITH s AS (
  SELECT CAST(p_codmes AS INTEGER) AS p_codmes, tip_doc, key_value, prob_modelo_cal,
         ROW_NUMBER() OVER (PARTITION BY p_codmes, tip_doc, key_value ORDER BY fec_replica DESC) AS rn
  FROM disc_model_owner.scr_admbankbpe_calibrado_202607
),
j AS (
  SELECT d.cod_mes, d.meses_madurez, d.target_12m,
         GREATEST(1e-6, LEAST(1 - 1e-6,
           s.prob_modelo_cal * CASE WHEN d.cod_tip_doc = '2' THEN 0.68140 ELSE 0.96970 END)) AS pd_esc_opt
  FROM disc_model_owner.b46029_desemb_cal_202609 d
  JOIN s ON s.tip_doc = d.cod_tip_doc AND s.key_value = d.key_value AND s.p_codmes = d.cod_mes AND s.rn = 1
  WHERE d.desc_producto NOT IN ('IMPULSO','GARANTIAS','BONO BUEN PAGADOR','FONDO CRECER')
    AND d.pd_raw IS NOT NULL
)
SELECT cod_mes,
       COUNT(*) AS n,
       ROUND(100 * AVG(pd_esc_opt), 3) AS pd_escopt_pct,
       ROUND(100 * AVG(CASE WHEN meses_madurez = 12 THEN target_12m END), 3) AS rd12_pct
FROM j GROUP BY cod_mes ORDER BY cod_mes;
