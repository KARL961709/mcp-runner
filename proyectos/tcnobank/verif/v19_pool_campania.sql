-- ============================================================================
-- V19. EL POOL DE CAMPANIA ES MAS POBRE EN DATOS QUE LA BASE DE ALTAS
--   scan: scr_vcnbank_rsk en 202412 U plin U 360 U cta sueldo, con semijoins
--   ancla: la base de calibracion son ALTAS de IBK, gente que ya acepto una tarjeta y
--          por lo tanto autoseleccionada hacia tener relacion con el banco. En campania
--          se puntuan PROSPECTOS. Si el pool puntuable tiene mucha menos huella, la LRA
--          de N3 no representa a quien se le va a aplicar
--   se mide la misma composicion en los dos lados para el mismo mes
-- ============================================================================
WITH sc AS (
    SELECT DISTINCT key_value, cod_tip_doc
    FROM e_perm_aws.scr_vcnbank_rsk
    WHERE p_codmes = '202412'
),
pl AS (
    SELECT DISTINCT CAST(cif_key AS VARCHAR) AS k
    FROM e_perm_aws.t_agg_retail_user_trx_plin
    WHERE p_codmes BETWEEN '202409' AND '202411'
),
tr AS (
    SELECT DISTINCT key_value AS k, CAST(cod_tipo_documento AS VARCHAR) AS t
    FROM e_perm_aws.t_aws_360_cliente_mes_d3
    WHERE CAST(codmes AS VARCHAR) BETWEEN '202406' AND '202411'
),
cs AS (
    SELECT DISTINCT CAST(key_value AS VARCHAR) AS k,
           CAST(CAST(tipdoc AS INTEGER) AS VARCHAR) AS t
    FROM e_perm_aws.t_rsk_cta_sueldo
    WHERE CAST(codmes AS VARCHAR) = '202411'
),
pool AS (
    SELECT 'A. pool puntuable 202412'                                                   AS lado,
           CASE WHEN p.k IS NOT NULL THEN 1 ELSE 0 END                                  AS con_plin,
           CASE WHEN r.k IS NOT NULL THEN 1 ELSE 0 END                                  AS con_360,
           CASE WHEN c.k IS NOT NULL THEN 1 ELSE 0 END                                  AS con_cs
    FROM sc s
    LEFT JOIN pl p ON p.k = s.key_value
    LEFT JOIN tr r ON r.k = s.key_value AND r.t = CAST(s.cod_tip_doc AS VARCHAR)
    LEFT JOIN cs c ON c.k = s.key_value AND c.t = CAST(s.cod_tip_doc AS VARCHAR)
),
altas AS (
    SELECT 'B. altas IBK 202412'                                                        AS lado,
           1 - ctrl_sin_plin                                                            AS con_plin,
           1 - ctrl_sin_360                                                             AS con_360,
           1 - ctrl_sin_cta_sueldo                                                      AS con_cs
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal
    WHERE flg_calib = 1 AND flg_clean = 1
      AND entidad = '00002' AND codmes_mrm = '202412'
),
u AS (
    SELECT * FROM pool
    UNION ALL
    SELECT * FROM altas
)
SELECT lado,
       count(*)                                                                         AS n,
       round(100.0 * avg(CAST(con_plin AS DOUBLE)), 3)                                  AS pct_con_plin,
       round(100.0 * avg(CAST(con_360  AS DOUBLE)), 3)                                  AS pct_con_360,
       round(100.0 * avg(CAST(con_cs   AS DOUBLE)), 3)                                  AS pct_con_cs,
       round(100.0 * avg(CASE WHEN con_plin + con_360 + con_cs = 0
                              THEN 1.0 ELSE 0.0 END), 3)                                AS pct_sin_ninguna,
       round(100.0 * avg(CASE WHEN con_plin + con_360 + con_cs = 3
                              THEN 1.0 ELSE 0.0 END), 3)                                AS pct_con_las_tres
FROM u
GROUP BY lado
ORDER BY lado
