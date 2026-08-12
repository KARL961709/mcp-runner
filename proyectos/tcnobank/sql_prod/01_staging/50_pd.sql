-- 50_pd.sql | PD cruda del modelo vcnbank. prob_model es la salida directa del CatBoost y es lo que se calibra.
-- Anclaje: p_codmes del score = codmes_mrm, igual que produccion, donde codmes_scr = codmes_mrm. La q22 verifico que
-- cod_mes y p_codmes coinciden en la tabla de score, asi que la particion sirve de ancla sin ambiguedad.
-- Se traen ademas los campos de la calibracion VIGENTE (grupo_calibracion, prob_modelo_cal, puntuacion_cal) como
-- referencia de contraste, no como insumo: esa calibracion se descarta por decision del propietario. Son dos arboles
-- de tres hojas sobre inflacion y desempleo que aplican un shift aditivo en logit sin ancla de nivel ni pendiente.
-- La q24 midio que la brecha real pide pendiente 1.15 en espacio probit, que un shift puro no puede dar.
CREATE TABLE disc_model_owner.ds_adm_tcnb_50_pd
WITH (
    format              = 'PARQUET',
    parquet_compression = 'SNAPPY',
    partitioned_by      = ARRAY['codmes_mrm'],
    external_location   = '<S3_DATOS>/adm_tcnb_50_pd/'
) AS
WITH po AS (
    SELECT DISTINCT codmes_mrm, tip_doc, id_value FROM disc_model_owner.ds_adm_tcnb_10_po
)
SELECT p.tip_doc,
       p.id_value,
       TRY_CAST(s.prob_model      AS DOUBLE)                                           AS pd_raw,
       TRY_CAST(s.puntuacion      AS INTEGER)                                          AS puntuacion,
       TRY_CAST(s.prob_modelo_cal AS DOUBLE)                                           AS pd_cal_vigente,
       TRY_CAST(s.puntuacion_cal  AS INTEGER)                                          AS puntuacion_cal_vigente,
       s.grupo_calibracion                                                             AS grupo_cal_vigente,
       s.tip_situacion_laboral                                                         AS sitlab_score,
       TRY_CAST(s.rat_expect_inflacion  AS DOUBLE)                                      AS macro_inflacion,
       TRY_CAST(s.rat_tasa_desempleo    AS DOUBLE)                                      AS macro_desempleo,
       TRY_CAST(s.rat_tasa_desempleo_6  AS DOUBLE)                                      AS macro_desempleo_6,
       CAST(CASE WHEN s.key_value IS NULL THEN 1 ELSE 0 END AS INTEGER)                AS falla_sin_score,
       p.codmes_mrm
FROM po p
LEFT JOIN e_perm_aws.scr_vcnbank_rsk s
       ON s.cod_tip_doc = p.tip_doc
      AND s.key_value   = p.id_value
      AND s.p_codmes    = p.codmes_mrm
