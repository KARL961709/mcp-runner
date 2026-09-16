-- p05 scored PILOTO 202401 PP-only (Facil+CD) desde nodos_pil. beta/iso + celda/overlay + Vasicek(lambda1, sqrt0.98326) con ft_pp REAL 202401=0.0500972213.
--   flg_clean = 1 - flg_dirty_pp (clasif-only, idem 2609). puntuacion = round(1000*(1-prob)). PIT y TTC. Sin EC ni TC.
CREATE TABLE disc_model_owner.scr_admvc_pp_cal_202401_202606
WITH (format = 'PARQUET', write_compression = 'SNAPPY', partitioned_by = ARRAY['codmes']) AS
WITH
coef_iso_pc(x_lo, x_hi, y_lo, y_hi) AS (VALUES
    (CAST(0.0000000000 AS double), CAST(0.0049012722 AS double), CAST(0.0000000000 AS double), CAST(0.0000000000 AS double)),
    (0.0049012722, 0.0191014837, 0.0000000000, 0.0000000000),
    (0.0191014837, 0.0191031024, 0.0000000000, 0.0020876827),
    (0.0191031024, 0.0259118378, 0.0020876827, 0.0020876827),
    (0.0259118378, 0.0259232763, 0.0020876827, 0.0056818182),
    (0.0259232763, 0.0280636102, 0.0056818182, 0.0056818182),
    (0.0280636102, 0.0280724056, 0.0056818182, 0.0140127389),
    (0.0280724056, 0.0362343565, 0.0140127389, 0.0140127389),
    (0.0362343565, 0.0362353250, 0.0140127389, 0.0142857143),
    (0.0362353250, 0.0370077863, 0.0142857143, 0.0142857143),
    (0.0370077863, 0.0370172597, 0.0142857143, 0.0161290323),
    (0.0370172597, 0.0377028733, 0.0161290323, 0.0161290323),
    (0.0377028733, 0.0377206430, 0.0161290323, 0.0239361702),
    (0.0377206430, 0.0591382273, 0.0239361702, 0.0239361702),
    (0.0591382273, 0.0591516942, 0.0239361702, 0.0305569246),
    (0.0591516942, 0.0890215412, 0.0305569246, 0.0305569246),
    (0.0890215412, 0.0890233517, 0.0305569246, 0.0438950555),
    (0.0890233517, 0.1521715373, 0.0438950555, 0.0438950555),
    (0.1521715373, 0.1521926373, 0.0438950555, 0.0481927711),
    (0.1521926373, 0.1572412252, 0.0481927711, 0.0481927711),
    (0.1572412252, 0.1572542340, 0.0481927711, 0.0784313725),
    (0.1572542340, 0.1813758165, 0.0784313725, 0.0784313725),
    (0.1813758165, 0.1815660596, 0.0784313725, 0.0807017544),
    (0.1815660596, 0.2365446240, 0.0807017544, 0.0807017544),
    (0.2365446240, 0.2376354784, 0.0807017544, 0.1027397260),
    (0.2376354784, 0.4905883968, 0.1027397260, 0.1027397260),
    (0.4905883968, 0.4960871339, 0.1027397260, 0.5000000000),
    (0.4960871339, 0.7061473727, 0.5000000000, 0.5000000000),
    (0.7061473727, 1.0000001000, 0.5000000000, 0.5000000000)
),
coef_celda_pp(ak, delta) AS (VALUES
    (CAST('n|PP_CD|NODO 1' AS varchar), CAST(-0.2055440663 AS double)),
    ('p|PP_CD', 0.0336699142),
    ('p|PP_FACIL', 0.0200476882),
    ('t|PP_CD|DEP|NODO 2', -0.0198757939),
    ('t|PP_CD|NO_DEP|NODO 2', 0.1012549169),
    ('t|PP_FACIL|DEP|NODO 1', -0.2243960185),
    ('t|PP_FACIL|DEP|NODO 2', -0.1168821994),
    ('t|PP_FACIL|DEP|NODO 3', 0.0143330720),
    ('t|PP_FACIL|NO_DEP|NODO 1', -0.0053696648),
    ('t|PP_FACIL|NO_DEP|NODO 2', 0.0318394217),
    ('t|PP_FACIL|NO_DEP|NODO 3', 0.1148414333)
),
coef_ft_pp(codmes, ft) AS (VALUES
    (CAST('202401' AS varchar), CAST(0.0500972213 AS double))
),
base AS (
  SELECT n.cod_tip_doc, n.key_value, n.tipo_ingreso, n.nodo_ppfacil, n.nodo_ppcd, n.flg_dirty_pp, n.codmes,
         CAST(n.pd_raw AS double) AS pd_raw,
         greatest(least(CAST(n.pd_raw AS double), 1 - 1e-06), 1e-06) AS p
  FROM disc_model_owner.scr_admvc_pp_cal_202401_202606_nodos n
),
cal AS (
  SELECT b.*,
    1.0 / (1.0 + exp(-(-0.1460672524 + 1.0405635434 * ln(b.p) - 2.5746e-11 * ln(1 - b.p)))) AS pcal_ppfacil,
    ic.y_lo + (ic.y_hi - ic.y_lo) * (b.p - ic.x_lo) / (ic.x_hi - ic.x_lo) AS pcal_ppcd
  FROM base b
  LEFT JOIN coef_iso_pc ic ON b.p >= ic.x_lo AND b.p < ic.x_hi
),
anch AS (
  SELECT c.*,
    CASE WHEN c.flg_dirty_pp = 1 THEN 0.0722597767 ELSE COALESCE(ff_t.delta, ff_n.delta, ff_p.delta, 0.0) END AS delta_ppfacil,
    CASE WHEN c.flg_dirty_pp = 1 THEN 0.0722597767 ELSE COALESCE(cd_t.delta, cd_n.delta, cd_p.delta, 0.0) END AS delta_ppcd,
    COALESCE(ft.ft, 0.0) AS ftv_pp
  FROM cal c
  LEFT JOIN coef_celda_pp ff_t ON ff_t.ak = 't|PP_FACIL|' || c.tipo_ingreso || '|' || c.nodo_ppfacil
  LEFT JOIN coef_celda_pp ff_n ON ff_n.ak = 'n|PP_FACIL|' || c.nodo_ppfacil
  LEFT JOIN coef_celda_pp ff_p ON ff_p.ak = 'p|PP_FACIL'
  LEFT JOIN coef_celda_pp cd_t ON cd_t.ak = 't|PP_CD|' || c.tipo_ingreso || '|' || c.nodo_ppcd
  LEFT JOIN coef_celda_pp cd_n ON cd_n.ak = 'n|PP_CD|' || c.nodo_ppcd
  LEFT JOIN coef_celda_pp cd_p ON cd_p.ak = 'p|PP_CD'
  LEFT JOIN coef_ft_pp ft ON ft.codmes = c.codmes
),
scored AS (
  SELECT a.*,
    normal_cdf(0, 1, (inverse_normal_cdf(0, 1, greatest(least(a.pcal_ppfacil, 1 - 1e-06), 1e-06)) + a.delta_ppfacil + 1.000000 * a.ftv_pp) / 0.9832598843) AS prob_ppfacil,
    normal_cdf(0, 1, (inverse_normal_cdf(0, 1, greatest(least(a.pcal_ppcd, 1 - 1e-06), 1e-06)) + a.delta_ppcd + 1.000000 * a.ftv_pp) / 0.9832598843) AS prob_ppcd,
    normal_cdf(0, 1, (inverse_normal_cdf(0, 1, greatest(least(a.pcal_ppfacil, 1 - 1e-06), 1e-06)) + a.delta_ppfacil) / 0.9832598843) AS prob_ppfacil_ttc,
    normal_cdf(0, 1, (inverse_normal_cdf(0, 1, greatest(least(a.pcal_ppcd, 1 - 1e-06), 1e-06)) + a.delta_ppcd) / 0.9832598843) AS prob_ppcd_ttc
  FROM anch a
)
SELECT
    cod_tip_doc, key_value, pd_raw AS prob_modelo, tipo_ingreso, nodo_ppfacil, nodo_ppcd, flg_dirty_pp,
    CASE WHEN flg_dirty_pp = 1 THEN 0 ELSE 1 END AS flg_clean,
    prob_ppfacil AS prob_modelo_cal_ppfacil,
    prob_ppcd    AS prob_modelo_cal_ppcd,
    prob_ppfacil_ttc AS prob_modelo_ttc_ppfacil,
    prob_ppcd_ttc    AS prob_modelo_ttc_ppcd,
    CAST(round(1000.0 * (1 - prob_ppfacil)) AS integer) AS puntuacion_modelo_cal_ppfacil,
    CAST(round(1000.0 * (1 - prob_ppcd))    AS integer) AS puntuacion_modelo_cal_ppcd,
    CAST(round(1000.0 * (1 - prob_ppfacil_ttc)) AS integer) AS puntuacion_modelo_ttc_ppfacil,
    CAST(round(1000.0 * (1 - prob_ppcd_ttc))    AS integer) AS puntuacion_modelo_ttc_ppcd,
    ftv_pp AS ft_macro_pp,
    codmes
FROM scored
