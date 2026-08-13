-- ============================================================================
-- 13. PASIVOS Y RETIRO AFP
--   scan: t_aws_360_cliente_mes_d3 en [codmes-6, codmes-1] U t_fact_edc_solicitud_retiro_afp_ibk
--   ancla: ventana [M-6, M-1] como el script de nodos en las lineas 3063 a 3068, o sea
--          SIN el mes de la decision, que en campania todavia no cerro
--   el script suma saldo_fdp_tot_pas_sin_cts de datalab, que no alcanzamos. El 360
--   trae las dos piezas por separado, asi que se reconstruye como pasivo menos cts.
--   Una suma de componentes sueltos queda corta: es un subconjunto del total
--   umbral ESTRICTO > 900 como la linea 3047, no mayor-igual
--   AFP anclado en codmes de la solicitud <= codmes del alta, igual que el script. Sin
--   filtro de abono para replicar. La variante con abono viaja como control
-- ============================================================================
CREATE TABLE disc_model_owner.ds_adm_vcnbank_tc_13_pasivos AS
WITH po AS (
    SELECT DISTINCT codmes_mrm, tip_doc, id_value,
           date_format(date_add('month', -6, date_parse(codmes_mrm, '%Y%m')), '%Y%m')   AS m06,
           date_format(date_add('month', -1, date_parse(codmes_mrm, '%Y%m')), '%Y%m')   AS m01
    FROM disc_model_owner.ds_adm_vcnbank_tc_11_po_key
),
s AS (
    SELECT p.codmes_mrm,
           p.tip_doc,
           p.id_value,
           p.m01,
           CAST(a.codmes AS VARCHAR)                                                    AS codmes,
           max(  coalesce(TRY_CAST(a.saldo_fdp_tot_pasivo AS DOUBLE), 0)
               - coalesce(TRY_CAST(a.saldo_fdp_tot_cts    AS DOUBLE), 0))               AS saldo
    FROM po p
    INNER JOIN e_perm_aws.t_aws_360_cliente_mes_d3 a
           ON a.key_value = p.id_value
          AND CAST(a.cod_tipo_documento AS VARCHAR) = p.tip_doc
          AND CAST(a.codmes AS VARCHAR) BETWEEN p.m06 AND p.m01
    GROUP BY p.codmes_mrm, p.tip_doc, p.id_value, p.m01, CAST(a.codmes AS VARCHAR)
),
f AS (
    SELECT codmes_mrm, tip_doc, id_value,
           count(*)                                                                     AS n_meses_360,
           count(CASE WHEN saldo > 900 THEN 1 END)                                     AS n_meses_900,
           max(CASE WHEN codmes = m01 THEN saldo END)                                   AS saldo_m01
    FROM s
    GROUP BY codmes_mrm, tip_doc, id_value
),
afp AS (
    SELECT DISTINCT CAST(key_value AS VARCHAR)                                          AS id_value,
           CAST(cod_tip_doc AS VARCHAR)                                                 AS tip_doc,
           date_format(ts_solicitud, '%Y%m')                                            AS codmes_retiro,
           CAST(flg_abono AS INTEGER)                                                   AS flg_abono
    FROM e_perm_aws.t_fact_edc_solicitud_retiro_afp_ibk
),
r AS (
    SELECT p.codmes_mrm, p.tip_doc, p.id_value,
           max(CASE WHEN a.codmes_retiro <= p.codmes_mrm THEN 1 ELSE 0 END)             AS retiro_afp,
           max(CASE WHEN a.codmes_retiro <= p.codmes_mrm AND a.flg_abono = 1
                    THEN 1 ELSE 0 END)                                                  AS retiro_afp_abonado
    FROM po p
    INNER JOIN afp a ON a.id_value = p.id_value AND a.tip_doc = p.tip_doc
    GROUP BY p.codmes_mrm, p.tip_doc, p.id_value
)
SELECT p.tip_doc,
       p.id_value,
       CAST(coalesce(f.n_meses_360, 0) AS INTEGER)                                      AS n_meses_360,
       CAST(coalesce(f.n_meses_900, 0) AS INTEGER)                                      AS n_meses_900,
       coalesce(f.saldo_m01, 0)                                                         AS saldo_pasivo_m01,
       CAST(CASE WHEN f.n_meses_900 = 6 THEN 1 ELSE 0 END AS INTEGER)                   AS flg_pasivo_6m,
       CAST(coalesce(r.retiro_afp, 0) AS INTEGER)                                       AS ctrl_retiro_afp,
       CAST(coalesce(r.retiro_afp_abonado, 0) AS INTEGER)                               AS ctrl_retiro_afp_abonado,
       CAST(CASE WHEN f.n_meses_900 = 6 AND coalesce(r.retiro_afp, 0) = 0
                 THEN 1 ELSE 0 END AS INTEGER)                                          AS flag_pasivos_afp_f,
       CAST(CASE WHEN f.id_value IS NULL THEN 1 ELSE 0 END AS INTEGER)                  AS ctrl_sin_360,
       p.codmes_mrm
FROM po p
LEFT JOIN f ON f.codmes_mrm = p.codmes_mrm AND f.tip_doc = p.tip_doc AND f.id_value = p.id_value
LEFT JOIN r ON r.codmes_mrm = p.codmes_mrm AND r.tip_doc = p.tip_doc AND r.id_value = p.id_value
