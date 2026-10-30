-- ============================================================================
-- 20. PD CALIBRADA del stock PP -- V1 (relanclaje) y V2 FINAL, en paralelo.
--
-- TODO PARTE DE FUENTES MADRE, ninguna tabla intermedia del pipeline:
--   score              disc_model_owner.scr_stk_ree_pp_cal_2023_202610 (prob_modelo)
--   situacion laboral  e_perm_aws.ds_rtd_rskvol_cas_ingr_ir   -> tipo_ingreso
--   cuenta sueldo      e_perm_aws.t_rsk_cta_sueldo            -> flg_cs
--   macro              e_perm_aws.t_mst_bcrp_rsk (porc_ipc)   -> f_t de las dos
--
-- porc_ipc es la variacion MENSUAL del IPC, no la interanual pese al nombre
-- (v29 y el indice ipc: identica al m/m a 1.1e-14 en 86 meses). De ahi:
--   V1  MA6 lag5 de porc_ipc DIRECTO -- la spec del v5, que es mensual
--   V2  interanual COMPUESTA (exp(sum(ln(1+x/100)))-1)*100 sobre 12 meses, luego
--       MA3 lag0 -- la spec de PP VC, que es interanual
--   Son series DISTINTAS, no dos rezagos de la misma. Ese era el error del funnel.
--
-- ANCLA: codmes_drv = codmes. El master 2609 cruza la pd mes con mes (v33 lo
-- probo contra Athena en 6 cohortes de control), asi que los drivers y el f_t se
-- leen en el MISMO mes del score, no en codmes-1 como el SQL anterior.
-- OJO -- SUPUESTO NO VERIFICADO AQUI: que leer los drivers en codmes reproduzca
-- el tipo_ingreso_dep del master. La verificacion de abajo usa el segmento del
-- master, asi que NO lo prueba. Correr antes v39_valida_driver_mes.sql.
--
-- V1 = BetaCal + macro + rho + lambda + cap CONGELADOS del v5. Solo el delta
--      probit se re-resolvio sobre el master 2609 (DEP +0.2211, NO DEP +0.2423).
-- V2 = V2-FINAL-PLATT-MA3LAG0, la especificacion cerrada y validada:
--        calibrador PLATT por celda, 1/(1+exp(-(a*logit(p)+b))) -- gano el
--          benchmark de 10 familias fuera de muestra
--        delta por celda, re-anclado a la LRA del perimetro verificado
--        rho POR CELDA (Basilea other-retail en la PD del propio segmento),
--          no el 0.0332 heredado, que es la curva en PD 10.58 pct de otro modelo
--        lambda 1.00 -- la pendiente medida, sin amortiguar. En la ventana larga
--          201904-202509 la pendiente es 0.849 (t HAC 3.91) y su IC95 contiene 1
--        cap [-0.0303843813, +0.3472136826] = p5/p95 de ft sobre 201901-202509.
--          Casi inerte: muerde 8 de 33 meses, todos por el piso, y mueve la PD
--          +0.15 pct en media. Se mantiene por prudencia, no porque decida
--        piso 0.0003 (3 pb)
--
-- Limitaciones declaradas en ESPECIFICACION.json (12). Las dos que importan
-- para leer esta tabla: lambda no se identifica dentro de V4 aislada, y la
-- celda DEP tiene un codo entre q2 y q3 que Platt no dobla (Hosmer-Lemeshow
-- p = 0.0020). Ninguna se corrige aca.
--
-- NO LLEVA MoC. El shift del MoC se estimo con lambda=1, a=1 y cap, y no se
-- re-estimo para esta configuracion. Es una capa aparte, no va dentro del CTAS.
--
-- Las dos anclan la LRA del PERIMETRO REENGANCHE, no la del stock. Sobre el stock
-- completo el nivel queda corrido: sirve para comparar V1 contra V2 (mismo sesgo
-- de nivel) y para aterrizar despues a altas por codmes.
--
-- Verificado en 30_genera_sql_final.py contra el pipeline, antes de escribirse:
--   V1 pd_pit 0.0e+00      V2 pd_pit 0.0e+00
-- ============================================================================
CREATE TABLE disc_model_owner.scr_stk_ree_pp_cal_v1v2
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
         f1.f_t AS f_t_v1,
         f2.f_t AS f_t_v2,
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
       f_t_v1                  AS trf_f_t_v1,
       f_t_v2                  AS trf_f_t_v2,
       pcal_v1                 AS trf_betacal_v1,
       pcal_v2                 AS trf_platt_v2,
       pit_v1                  AS prob_modelo_cal_v1,
       pit_v2                  AS prob_modelo_cal_v2,
       CAST(round((1.0 - pit_v1) * 1000) AS INTEGER) AS puntuacion_cal_v1,
       CAST(round((1.0 - pit_v2) * 1000) AS INTEGER) AS puntuacion_cal_v2
FROM fin
