-- ============================================================================
-- v36. EL DESEMBOLSO MANDA. Que mes de score es PRE y cual es POST.
--
--   La pregunta del ancla no se puede cerrar con nombres de columna: ni
--   codmes_mrm ni cod_mes traen su significado escrito. Se cierra con el
--   DESEMBOLSO, que es un hecho con fecha. Si el reenganche se desembolsa en el
--   mes D, entonces el archivo de score que todavia NO lo ve es pre-desembolso
--   y el que ya lo ve esta contaminado.
--
--   Poblacion: los desembolsos de REENGANCHE, tomados de su propia tabla, sin
--   pasar por el perimetro ni por la tabla gobernada. Esa es la independencia.
--   Para cada mes de desembolso D se lee la MISMA gente en tres archivos:
--     pd_Dm1  cod_mes = D - 1
--     pd_D    cod_mes = D
--     pd_D1   cod_mes = D + 1
--
--   LECTURA:
--     pd_Dm1 ~ pd_D  y  pd_D1 mucho mas alta  -> el salto entra en D+1, asi que
--        D es el ultimo archivo limpio y el ancla correcta es codmes_mrm = D.
--        Es la firma de la PD post-desembolso: el archivo D+1 refleja el cierre
--        de D, cuando el reenganche ya esta en el balance del cliente.
--     el salto ya entre pd_Dm1 y pd_D -> el archivo D tambien esta contaminado
--        y el ancla limpia seria D-1, no D. Eso tumbaria la Opcion 2 tal como
--        esta planteada, asi que es la hipotesis que mas importa poder rechazar.
--
--   Aritmetica de meses con DATE_ADD sobre DATE_PARSE, nunca resta entera (O6).
--   La tabla de desembolsos se DEDUPLICA por llave: varios desembolsos del mismo
--   cliente en el mes inflarian el promedio sin cambiar la pd.
-- ============================================================================
WITH des AS (
  SELECT DISTINCT
         CAST(cod_mes AS VARCHAR)   AS mes_d,
         CAST(tip_doc AS VARCHAR)   AS tip_doc,
         CAST(key_value AS VARCHAR) AS id_value
  FROM e_perm_aws.t_fact_rsk_desembolsos_pp
  WHERE desc_producto_agrupado IN ('REENGANCHE', 'Reenganche')
    AND CAST(cod_mes AS VARCHAR) IN ('202302', '202306', '202312', '202406', '202506', '202509')
),
ejes AS (
  SELECT mes_d,
         tip_doc,
         id_value,
         DATE_FORMAT(DATE_ADD('month', -1, DATE_PARSE(mes_d, '%Y%m')), '%Y%m') AS mes_m1,
         DATE_FORMAT(DATE_ADD('month',  1, DATE_PARSE(mes_d, '%Y%m')), '%Y%m') AS mes_p1
  FROM des
),
src AS (
  SELECT CAST(cod_mes AS VARCHAR)         AS mes,
         CAST(cod_tip_doc AS VARCHAR)     AS tip_doc,
         CAST(key_value AS VARCHAR)       AS id_value,
         MAX(CAST(prob_modelo AS DOUBLE)) AS pd
  FROM disc_model_owner.scr_stk_ree_pp_cal_2023_202610
  WHERE prob_modelo IS NOT NULL
  GROUP BY 1, 2, 3
)
SELECT e.mes_d                                     AS mes_desembolso,
       COUNT(*)                                    AS n_desembolsos,
       COUNT(a.pd)                                 AS n_Dm1,
       ROUND(100.0 * AVG(a.pd), 4)                 AS pd_Dm1,
       COUNT(b.pd)                                 AS n_D,
       ROUND(100.0 * AVG(b.pd), 4)                 AS pd_D,
       COUNT(c.pd)                                 AS n_D1,
       ROUND(100.0 * AVG(c.pd), 4)                 AS pd_D1
FROM ejes e
LEFT JOIN src a ON a.mes = e.mes_m1 AND a.tip_doc = e.tip_doc AND a.id_value = e.id_value
LEFT JOIN src b ON b.mes = e.mes_d  AND b.tip_doc = e.tip_doc AND b.id_value = e.id_value
LEFT JOIN src c ON c.mes = e.mes_p1 AND c.tip_doc = e.tip_doc AND c.id_value = e.id_value
GROUP BY e.mes_d
ORDER BY 1
