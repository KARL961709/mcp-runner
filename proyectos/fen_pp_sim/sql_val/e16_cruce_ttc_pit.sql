-- e16_cruce_ttc_pit.sql | cruce grado-TTC x grado-PIT (para la migracion TTC -> PIT bien hecha).
-- Cada grado se asigna sobre SU PROPIO score con los cortes 2609 (TTC sobre puntuacion_modelo_ttc_cal_ppfacil,
-- PIT sobre puntuacion_modelo_cal_ppfacil). Devuelve la matriz de conteos (max 49 filas) + PD promedio por celda.
-- Con esto se dibuja el flujo TTC->PIT real (la TTC through-the-cycle es mas benigna; PIT es la del momento).
-- Read-only. Correr:  .\Go.ps1 -SqlDir proyectos/fen_pp_sim/sql_val -Only e16_cruce_ttc_pit
WITH camp AS (
  SELECT DISTINCT substr(subject_id, 3) AS kv
  FROM d_perm_aws.t_edc_ar_camp_vars_sep2qrec_temp
  WHERE p_codmes = '202609' AND producto = 'PP' AND sub_producto = 'PP' AND num_carga = '2.1 Rec'
),
g AS (
  SELECT
    CASE WHEN u.puntuacion_modelo_ttc_cal_ppfacil>=985 THEN 'G1' WHEN u.puntuacion_modelo_ttc_cal_ppfacil>=955 THEN 'G2'
         WHEN u.puntuacion_modelo_ttc_cal_ppfacil>=947 THEN 'G3' WHEN u.puntuacion_modelo_ttc_cal_ppfacil>=912 THEN 'G4'
         WHEN u.puntuacion_modelo_ttc_cal_ppfacil>=892 THEN 'G5' WHEN u.puntuacion_modelo_ttc_cal_ppfacil>=864 THEN 'G6' ELSE 'GR' END AS gttc,
    CASE WHEN u.puntuacion_modelo_cal_ppfacil>=985 THEN 'G1' WHEN u.puntuacion_modelo_cal_ppfacil>=955 THEN 'G2'
         WHEN u.puntuacion_modelo_cal_ppfacil>=947 THEN 'G3' WHEN u.puntuacion_modelo_cal_ppfacil>=912 THEN 'G4'
         WHEN u.puntuacion_modelo_cal_ppfacil>=892 THEN 'G5' WHEN u.puntuacion_modelo_cal_ppfacil>=864 THEN 'G6' ELSE 'GR' END AS gpit
  FROM camp c
  JOIN d_perm_aws.scr_vcadmbnk_final_rsk_cal_2609 u ON u.key_value = c.kv
)
SELECT gttc, gpit, CAST(COUNT(*) AS varchar) AS n
FROM g GROUP BY gttc, gpit
ORDER BY gttc, gpit
