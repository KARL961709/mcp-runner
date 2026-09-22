-- e15_verifica_grados.sql | VERIFICA que el grado lo fija el SCORE y que PIT vs TTC gradúan casi igual.
-- Sobre la campana PP 202609 (cruzada a scores), gradua por el score PIT y por el score TTC con los MISMOS cortes 2609,
-- y cuenta cuantos cambian de grado entre uno y otro. Si el grueso queda en 'mismo_grado', confirma que raw/ttc como
-- columnas de grado NO aportan (misma foto) y que el ruido (TTC sin G3) era artefacto de graduar PD-TTC sobre cortes-PD-PIT.
-- Read-only. Correr:  .\Go.ps1 -SqlDir proyectos/fen_pp_sim/sql_val -Only e15_verifica_grados
WITH camp AS (
  SELECT DISTINCT substr(subject_id, 3) AS kv
  FROM d_perm_aws.t_edc_ar_camp_vars_sep2qrec_temp
  WHERE p_codmes = '202609' AND producto = 'PP' AND sub_producto = 'PP' AND num_carga = '2.1 Rec'
),
g AS (
  SELECT
    CASE WHEN u.puntuacion_modelo_cal_ppfacil>=985 THEN 'G1' WHEN u.puntuacion_modelo_cal_ppfacil>=955 THEN 'G2'
         WHEN u.puntuacion_modelo_cal_ppfacil>=947 THEN 'G3' WHEN u.puntuacion_modelo_cal_ppfacil>=912 THEN 'G4'
         WHEN u.puntuacion_modelo_cal_ppfacil>=892 THEN 'G5' WHEN u.puntuacion_modelo_cal_ppfacil>=864 THEN 'G6' ELSE 'GR' END AS gpit,
    CASE WHEN u.puntuacion_modelo_ttc_cal_ppfacil>=985 THEN 'G1' WHEN u.puntuacion_modelo_ttc_cal_ppfacil>=955 THEN 'G2'
         WHEN u.puntuacion_modelo_ttc_cal_ppfacil>=947 THEN 'G3' WHEN u.puntuacion_modelo_ttc_cal_ppfacil>=912 THEN 'G4'
         WHEN u.puntuacion_modelo_ttc_cal_ppfacil>=892 THEN 'G5' WHEN u.puntuacion_modelo_ttc_cal_ppfacil>=864 THEN 'G6' ELSE 'GR' END AS gttc,
    u.prob_modelo_cal_ppfacil AS pdpit, u.prob_modelo_ttc_cal_ppfacil AS pdttc
  FROM camp c
  JOIN d_perm_aws.scr_vcadmbnk_final_rsk_cal_2609 u ON u.key_value = c.kv
)
SELECT 'A_por_score_PIT' AS bloque, gpit AS grado, CAST(COUNT(*) AS varchar) AS n,
       CAST(ROUND(AVG(pdpit),5) AS varchar) AS pd_pit, CAST(ROUND(AVG(pdttc),5) AS varchar) AS pd_ttc
FROM g GROUP BY gpit
UNION ALL
SELECT 'B_por_score_TTC', gttc, CAST(COUNT(*) AS varchar), '', ''
FROM g GROUP BY gttc
UNION ALL
SELECT 'C_cambio_grado', CASE WHEN gpit=gttc THEN '1_mismo_grado' ELSE '2_cambia' END, CAST(COUNT(*) AS varchar), '', ''
FROM g GROUP BY (gpit=gttc)
ORDER BY bloque, grado
