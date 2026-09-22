-- ============================================================================
-- d2_05. INSERT trimestre 202410-202412 (RCC M-2 = 202408-202410) en drv_clean_ppvc.
-- ============================================================================
INSERT INTO disc_model_owner.drv_clean_ppvc
WITH rcc AS (
  SELECT CAST(codmes AS integer) AS rcc_codmes, key_value, TRY_CAST(tip_doc AS integer) AS tipd,
    MAX(CASE WHEN SUBSTR(cod_cuenta_rcc, 1, 10) IN ('1411030603','1414030603','1415030603','1416030603','1411031906','1414031906','1415031906','1416031906','1421030603','1424030603','1425030603','1426030603','1421031906','1424031906','1425031906','1426031906','1431030603','1434030603','1435030603','1436030603','1431031906','1434031906','1435031906','1436031906','1411030614','1414030614','1415030614','1416030614','1411030615','1414030615','1415030615','1416030615','1421030614','1424030614','1425030614','1426030614','1421030615','1424030615','1425030615','1426030615','1431030614','1434030614','1435030614','1436030614','1431030615','1434030615','1435030615','1436030615','1411030616','1414030616','1415030616','1416030616','1411039902','1414039902','1415039902','1416039902','1421030616','1424030616','1425030616','1426030616','1421039902','1424039902','1425039902','1426039902','1431030616','1434030616','1435030616','1436030616','1431039902','1434039902','1435039902','1436039902','1411031999','1414031999','1415031999','1416031999','1411030303','1414030303','1415030303','1416030303','1421031999','1424031999','1425031999','1426031999','1421030303','1424030303','1425030303','1426030303','1431031999','1434031999','1435031999','1436031999','1431030303','1434030303','1435030303','1436030303')
             AND tipo_credito IN ('11', '12') AND cod_clasificacion_deudor <> '8' THEN condicion END) AS dm_pp,
    SUM(CASE WHEN SUBSTR(cod_cuenta_rcc, 1, 2) = '81' AND SUBSTR(cod_cuenta_rcc, 4, 3) IN ('302', '925') THEN saldo END) AS cast_0m,
    SUM(CASE WHEN ((SUBSTR(cod_cuenta_rcc, 1, 2) = '14' AND SUBSTR(cod_cuenta_rcc, 4, 1) = '4') OR
                   (SUBSTR(cod_cuenta_rcc, 1, 2) || '0' || SUBSTR(cod_cuenta_rcc, 4, 1) IN ('1405', '1406') AND SUBSTR(cod_cuenta_rcc, 7, 2) = '19'))
             AND cod_clasificacion_deudor <> '8' THEN saldo END) AS ref_0m,
    SUM(CASE WHEN ((SUBSTR(cod_cuenta_rcc, 1, 2) = '14' AND SUBSTR(cod_cuenta_rcc, 4, 1) = '3') OR
                   (SUBSTR(cod_cuenta_rcc, 1, 2) || '0' || SUBSTR(cod_cuenta_rcc, 4, 1) IN ('1405', '1406') AND SUBSTR(cod_cuenta_rcc, 7, 2) = '22'))
             AND cod_clasificacion_deudor <> '8' THEN saldo END) AS ree_0m,
    SUM(CASE WHEN SUBSTR(cod_cuenta_rcc, 1, 2) = '14' AND SUBSTR(cod_cuenta_rcc, 4, 1) = '6'
             AND cod_clasificacion_deudor <> '8' THEN saldo END) AS jud_0m,
    MAX(CASE WHEN cod_clasificacion_deudor IN ('2', '3', '4') THEN 1 ELSE 0 END) AS clasif_cpp
  FROM e_perm_aws.t_fact_report_rcc_rsk
  WHERE CAST(codmes AS integer) BETWEEN 202408 AND 202410
  GROUP BY CAST(codmes AS integer), key_value, TRY_CAST(tip_doc AS integer)
),
base AS (
  SELECT key_value, cod_tip_doc, TRY_CAST(cod_tip_doc AS integer) AS tipd,
         CAST(DATE_FORMAT(DATE_PARSE(CAST(codmes AS varchar), '%Y%m') - INTERVAL '2' MONTH, '%Y%m') AS integer) AS rcc_codmes,
         codmes
  FROM d_perm_aws.scr_vcadmbnk_final_hist_rsk
  WHERE codmes BETWEEN '202410' AND '202412' AND probabilidad IS NOT NULL
)
SELECT b.cod_tip_doc AS tip_doc, b.key_value,
  CASE WHEN COALESCE(r.dm_pp, 0) > 0 THEN 1 ELSE 0 END AS flg_atraso,
  CASE WHEN COALESCE(r.cast_0m, 0) > 0 THEN 1 ELSE 0 END AS flg_cast,
  CASE WHEN COALESCE(r.ref_0m, 0) > 0 THEN 1 ELSE 0 END AS flg_ref,
  CASE WHEN COALESCE(r.ree_0m, 0) > 0 THEN 1 ELSE 0 END AS flg_ree,
  CASE WHEN COALESCE(r.jud_0m, 0) > 0 THEN 1 ELSE 0 END AS flg_jud,
  COALESCE(r.clasif_cpp, 0) AS flg_clasif,
  CASE WHEN COALESCE(r.dm_pp, 0) > 0 OR COALESCE(r.cast_0m, 0) > 0 OR COALESCE(r.ref_0m, 0) > 0
            OR COALESCE(r.ree_0m, 0) > 0 OR COALESCE(r.jud_0m, 0) > 0 OR COALESCE(r.clasif_cpp, 0) = 1
       THEN 0 ELSE 1 END AS flg_clean,
  CASE WHEN r.key_value IS NULL THEN 0 ELSE 1 END AS flg_rcc_hit,
  b.codmes AS codmes
FROM base b
LEFT JOIN rcc r ON b.rcc_codmes = r.rcc_codmes AND b.key_value = r.key_value AND b.tipd = r.tipd