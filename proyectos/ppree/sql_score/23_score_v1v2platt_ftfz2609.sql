-- ============================================================================
-- 23. PD CALIBRADA con el f_t CONGELADO en 202609 -- gemela de 21, para campana.
--
--   GENERADA por 32_genera_sql_ftfreeze.py DERIVANDO el CTAS desplegado
--   21_score_v1v2platt.sql. No se edita a mano: el bloque de macro se copia de
--   ahi con tres tokens cambiados, asi que los coeficientes no pueden divergir.
--
-- QUE CAMBIA RESPECTO DE disc_model_owner.scr_stk_ree_pp_cal_v1v2: NADA de la cadena.
--   Mismo Platt por celda, mismo delta, mismo rho por celda, mismo lambda 1.00,
--   mismo cap, mismo piso 0.0003. Cambia UNA cosa: de que mes se lee la macro.
--     tabla viva   f_t evaluado en el codmes de cada fila
--     esta tabla   f_t evaluado UNA vez en 202609 y aplicado a toda la tabla
--
-- POR QUE. Para campana la PD del cliente no debe moverse porque cambio la
--   inflacion del mes. Congelar el overlay en el ancla de la campana deja la
--   decision estable, y el nivel que el ancla fija es el de 202609.
--
-- LO QUE NO ES. No es una recalibracion ni cambia el ordenamiento: dentro de un
--   mes el f_t es un corrimiento comun a todas las filas, asi que el ranking y
--   el Gini son los MISMOS que en la tabla viva. Lo que cambia es el NIVEL de
--   los meses distintos de 202609, y con el nivel se mueven los cortes de grupo.
--   Para 202609 las dos tablas coinciden exactamente (v46 lo mide).
--
-- CONTRA QUE LEER EL IMPACTO. trf_f_t_v1_mes y trf_f_t_v2_mes traen el f_t que
--   le habria tocado al mes, al lado del congelado que se uso. La diferencia de
--   PD contra la tabla viva se mide con esas dos columnas sin ningun join.
--
-- MAGNITUD MEDIDA antes de construir (83_impacto_ft_congelado.py, sobre las PD
--   ya calculadas del perimetro, macro local -- el banco da el exacto en v47):
--     202609           f_t identico       delta 0.0000 pp     <- el mes del ancla
--     202608          f_t +0.0051        delta +0.04 pp
--     202606-202607   f_t +0.014         delta +0.11 pp
--     202603-202605   f_t +0.018 a 0.09  delta +0.13 a +0.61 pp
--     202409-202602   f_t +0.12 a 0.15   delta +0.69 a +1.04 pp   <- aca muerde
--   El efecto es MONOTONO en la brecha de macro, y 202609 es un mes de f_t ALTO
--   (inflacion interanual ~4.3 pct) contra un historico de f_t negativo. O sea:
--   congelar en 202609 es CONSERVADOR hacia atras y casi inocuo en el presente.
--
-- DONDE SI Y DONDE NO USAR ESTA TABLA.
--   SI  -- decidir campana sobre el stock de 202609 / 202610, que es para lo que
--          se pidio: ahi el f_t congelado y el vivo practicamente coinciden.
--   NO  -- validar nivel contra la RD realizada de meses historicos. En esos
--          meses la PD queda deliberadamente por encima de su propia RD (en la
--          ventana de fit el EC pasa de ~0 a ~+22 pct). Para eso esta la viva.
--   Y OJO con los cortes de grupo: estan en puntuacion = round((1-pd)*1000), asi
--   que al subir el nivel la poblacion migra hacia abajo. Sobre la ventana de fit
--   completa el reparto se mueve G1 -2.1 pp, G2 -8.4 pp, G4 +5.7 pp, G5 +2.7 pp,
--   G6 +3.6 pp. En el mes del ancla NO se mueve nada.
--
-- SI LA TABLA SALE VACIA, falta macro para 202609: el CROSS JOIN con el ancla es
--   deliberado para que eso falle ruidoso en vez de dejar la PD en NULL.
-- ============================================================================
CREATE TABLE disc_model_owner.scr_stk_ree_pp_cal_v1v2_ftfz2609
WITH (format = 'PARQUET', write_compression = 'SNAPPY') AS
WITH d AS (
  SELECT CAST(v.cod_mes AS VARCHAR) AS codmes,
         CAST(v.cod_mes AS VARCHAR) AS codmes_drv,
         CAST(v.cod_tip_doc AS VARCHAR) AS tip_doc,
         CAST(v.key_value AS VARCHAR) AS id_value,
         GREATEST(1e-9, LEAST(1.0 - 1e-9, AVG(v.prob_modelo))) AS p,
         MAX(v.puntuacion) AS puntuacion
  FROM disc_model_owner.scr_stk_ree_pp_cal_2023_202610 v
  WHERE v.prob_modelo IS NOT NULL
  GROUP BY CAST(v.cod_mes AS VARCHAR), CAST(v.cod_tip_doc AS VARCHAR), CAST(v.key_value AS VARCHAR)
),
spine AS (
  SELECT DISTINCT codmes_drv FROM d
),
spinez AS (
  SELECT '202609' AS codmes_drv
),
ft1 AS (
  SELECT c.codmes_drv,
         GREATEST(-1.1308495594, LEAST(0.7656842282,
           (-1.6467199676 - sqrt(1.0 - 0.0380301160) * (-1.9001957962 + 0.6583423568 * AVG(m.porc_ipc)))
           / sqrt(0.0380301160))) AS f_t
  FROM spine c
  JOIN e_perm_aws.t_mst_bcrp_rsk m
    ON m.cod_mes BETWEEN DATE_FORMAT(DATE_ADD('month', -10, DATE_PARSE(c.codmes_drv, '%Y%m')), '%Y%m')
                     AND DATE_FORMAT(DATE_ADD('month',  -5, DATE_PARSE(c.codmes_drv, '%Y%m')), '%Y%m')
  WHERE m.porc_ipc IS NOT NULL
  GROUP BY c.codmes_drv
  HAVING COUNT(m.porc_ipc) = 6
),
yy AS (
  SELECT c.codmes_drv, t.k,
         (exp(SUM(ln(1.0 + m.porc_ipc / 100.0))) - 1.0) * 100.0 AS yy
  FROM spine c
  CROSS JOIN UNNEST(ARRAY[0, 1, 2]) AS t(k)
  JOIN e_perm_aws.t_mst_bcrp_rsk m
    ON m.cod_mes BETWEEN DATE_FORMAT(DATE_ADD('month', -(t.k + 11), DATE_PARSE(c.codmes_drv, '%Y%m')), '%Y%m')
                     AND DATE_FORMAT(DATE_ADD('month', -t.k,        DATE_PARSE(c.codmes_drv, '%Y%m')), '%Y%m')
  WHERE m.porc_ipc IS NOT NULL
  GROUP BY c.codmes_drv, t.k
  HAVING COUNT(m.porc_ipc) = 12
),
ft2 AS (
  SELECT codmes_drv,
         GREATEST(-0.0303843813, LEAST(0.3472136826,
           0.0538554432 * (AVG(yy) - 2.1022638452))) AS f_t
  FROM yy
  GROUP BY codmes_drv
  HAVING COUNT(yy) = 3
),
ft1z AS (
  SELECT c.codmes_drv,
         GREATEST(-1.1308495594, LEAST(0.7656842282,
           (-1.6467199676 - sqrt(1.0 - 0.0380301160) * (-1.9001957962 + 0.6583423568 * AVG(m.porc_ipc)))
           / sqrt(0.0380301160))) AS f_t
  FROM spinez c
  JOIN e_perm_aws.t_mst_bcrp_rsk m
    ON m.cod_mes BETWEEN DATE_FORMAT(DATE_ADD('month', -10, DATE_PARSE(c.codmes_drv, '%Y%m')), '%Y%m')
                     AND DATE_FORMAT(DATE_ADD('month',  -5, DATE_PARSE(c.codmes_drv, '%Y%m')), '%Y%m')
  WHERE m.porc_ipc IS NOT NULL
  GROUP BY c.codmes_drv
  HAVING COUNT(m.porc_ipc) = 6
),
yyz AS (
  SELECT c.codmes_drv, t.k,
         (exp(SUM(ln(1.0 + m.porc_ipc / 100.0))) - 1.0) * 100.0 AS yy
  FROM spinez c
  CROSS JOIN UNNEST(ARRAY[0, 1, 2]) AS t(k)
  JOIN e_perm_aws.t_mst_bcrp_rsk m
    ON m.cod_mes BETWEEN DATE_FORMAT(DATE_ADD('month', -(t.k + 11), DATE_PARSE(c.codmes_drv, '%Y%m')), '%Y%m')
                     AND DATE_FORMAT(DATE_ADD('month', -t.k,        DATE_PARSE(c.codmes_drv, '%Y%m')), '%Y%m')
  WHERE m.porc_ipc IS NOT NULL
  GROUP BY c.codmes_drv, t.k
  HAVING COUNT(m.porc_ipc) = 12
),
ft2z AS (
  SELECT codmes_drv,
         GREATEST(-0.0303843813, LEAST(0.3472136826,
           0.0538554432 * (AVG(yy) - 2.1022638452))) AS f_t
  FROM yyz
  GROUP BY codmes_drv
  HAVING COUNT(yy) = 3
),
po AS (
  SELECT DISTINCT codmes_drv, tip_doc, id_value FROM d
),
cls AS (
  SELECT tip_doc, id_value, codmes, tipo_ingreso
  FROM (
    SELECT CAST(a.tip_doc AS VARCHAR) AS tip_doc,
           SUBSTR(a.subject_id, 3)    AS id_value,
           CAST(a.periodo AS VARCHAR) AS codmes,
           CASE
             WHEN a.sit_lab = 'DEPENDIENTE' AND a.fuente NOT IN ('INFERIDO','EXPERIAN','SUSALUD','INFERIDO_IND_MVP') THEN 'DEPENDIENTE'
             WHEN a.sit_lab = 'DEPENDIENTE' AND a.fuente IN ('INFERIDO','EXPERIAN','SUSALUD','INFERIDO_IND_MVP') THEN 'MIXTO'
             WHEN a.sit_lab = 'MIXTO' THEN 'MIXTO'
             ELSE 'INDEPENDIENTE'
           END AS tipo_ingreso,
           ROW_NUMBER() OVER (
             PARTITION BY SUBSTR(a.subject_id, 3), a.periodo, CAST(a.tip_doc AS VARCHAR)
             ORDER BY a.p_fecinformacion DESC, a.subject_id ASC) AS rn
    FROM e_perm_aws.ds_rtd_rskvol_cas_ingr_ir a
    INNER JOIN po b
      ON CAST(a.periodo AS VARCHAR) = b.codmes_drv
     AND SUBSTR(a.subject_id, 3) = b.id_value
    WHERE CAST(a.numcarga AS INT) = 1
  ) r
  WHERE rn = 1
),
cs AS (
  SELECT CAST(codmes AS VARCHAR)                  AS codmes,
         CAST(key_value AS VARCHAR)               AS id_value,
         CAST(CAST(tipdoc AS INTEGER) AS VARCHAR) AS tip_doc,
         MAX(CAST(flg_cs_riesgos AS INTEGER))     AS flg_cs
  FROM e_perm_aws.t_rsk_cta_sueldo
  GROUP BY 1, 2, 3
),
base AS (
  SELECT d.codmes, d.codmes_drv, d.tip_doc, d.id_value, d.p, d.puntuacion,
         f1.f_t AS f_t_v1_mes,
         f2.f_t AS f_t_v2_mes,
         z1.f_t AS f_t_v1,
         z2.f_t AS f_t_v2,
         COALESCE(c.tipo_ingreso, 'INDEPENDIENTE') AS tipo_ingreso,
         CASE WHEN COALESCE(c.tipo_ingreso, 'INDEPENDIENTE') = 'DEPENDIENTE' THEN 'DEP' ELSE 'NO DEP' END AS tipo_ingreso_dep,
         CASE
           WHEN s.id_value IS NULL THEN 'SIN_DATO'
           WHEN COALESCE(s.flg_cs, 0) = 1 THEN 'CS'
           ELSE 'NO_CS'
         END AS flg_cs_estado,
         CAST(CASE WHEN c.id_value IS NULL THEN 1 ELSE 0 END AS INTEGER) AS falla_sin_tipo_ingreso,
         CAST(CASE WHEN s.id_value IS NULL THEN 1 ELSE 0 END AS INTEGER) AS falla_sin_cta_sueldo
  FROM d
  LEFT JOIN cls c
         ON c.id_value = d.id_value AND c.tip_doc = d.tip_doc AND c.codmes = d.codmes_drv
  LEFT JOIN cs s
         ON s.id_value = d.id_value AND s.tip_doc = d.tip_doc
        AND s.codmes = DATE_FORMAT(DATE_ADD('month', -1, DATE_PARSE(d.codmes_drv, '%Y%m')), '%Y%m')
  LEFT JOIN ft1 f1 ON f1.codmes_drv = d.codmes_drv
  LEFT JOIN ft2 f2 ON f2.codmes_drv = d.codmes_drv
  CROSS JOIN ft1z z1
  CROSS JOIN ft2z z2
),
cal AS (
  SELECT b.*,
         CASE WHEN b.tipo_ingreso_dep = 'DEP'
              THEN 1.0/(1.0+exp(-(-1.4235902272 + 1.4307409241*ln(b.p) - 0.1167324222*ln(1.0-b.p))))
              ELSE 1.0/(1.0+exp(-(-1.8712301291 + 1.1219491911*ln(b.p) - 0.5587876582*ln(1.0-b.p))))
         END AS pcal_v1,
         CASE WHEN b.tipo_ingreso_dep = 'DEP'
              THEN 1.0/(1.0+exp(-(0.8762174855 * ln(b.p/(1.0-b.p)) + -2.2031459060)))
              ELSE 1.0/(1.0+exp(-(0.7612837267 * ln(b.p/(1.0-b.p)) + -2.1735504909)))
         END AS pcal_v2
  FROM base b
),
pit AS (
  SELECT cal.*,
         GREATEST(1e-4, LEAST(0.9999, normal_cdf(0.0, 1.0,
           (inverse_normal_cdf(0.0, 1.0, GREATEST(1e-9, LEAST(1.0-1e-9, pcal_v1)))
            + CASE WHEN tipo_ingreso_dep = 'DEP' THEN 0.2210674276 ELSE 0.2423447905 END
            - sqrt(0.0380301160) * 1.0 * f_t_v1) / sqrt(1.0 - 0.0380301160)))) AS pit_v1,
         GREATEST(0.0003000000, LEAST(0.9999, normal_cdf(0.0, 1.0,
           (inverse_normal_cdf(0.0, 1.0, GREATEST(1e-12, LEAST(1.0-1e-12, pcal_v2)))
            + CASE WHEN tipo_ingreso_dep = 'DEP' THEN 0.0621815628 ELSE 0.0625073998 END
            + 1.00 * f_t_v2)
           / CASE WHEN tipo_ingreso_dep = 'DEP' THEN sqrt(1.0 - 0.0798680000)
                  ELSE sqrt(1.0 - 0.0703540000) END))) AS pit_v2
  FROM cal
),
fin AS (
  SELECT pit.* FROM pit
)
SELECT codmes,
       codmes_drv,
       tip_doc,
       id_value                AS key_value,
       p                       AS probabilidad,
       puntuacion,
       tipo_ingreso            AS trf_tipo_ingreso,
       tipo_ingreso_dep        AS trf_tipo_ingreso_dep,
       flg_cs_estado           AS trf_flg_cs_estado,
       falla_sin_tipo_ingreso  AS trf_falla_sin_tipo_ingreso,
       falla_sin_cta_sueldo    AS trf_falla_sin_cta_sueldo,
       'BCRP'             AS trf_macro_fuente,
       '202609'           AS trf_codmes_ft,
       f_t_v1                  AS trf_f_t_v1,
       f_t_v2                  AS trf_f_t_v2,
       f_t_v1_mes              AS trf_f_t_v1_mes,
       f_t_v2_mes              AS trf_f_t_v2_mes,
       pcal_v1                 AS trf_betacal_v1,
       pcal_v2                 AS trf_platt_v2,
       pit_v1                  AS prob_modelo_cal_v1,
       pit_v2                  AS prob_modelo_cal_v2,
       CAST(round((1.0 - pit_v1) * 1000) AS INTEGER) AS puntuacion_cal_v1,
       CAST(round((1.0 - pit_v2) * 1000) AS INTEGER) AS puntuacion_cal_v2
FROM fin
