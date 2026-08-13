-- ============================================================================
-- V8. PLIN - COBERTURA CON EL DENOMINADOR CORRECTO
--   scan: ds_adm_vcnbank_tc_cal U t_agg_retail_user_trx_plin [202407,202504]
--   ancla: v7 dio 25.9 por ciento pero sobre el universo entero de 5 entidades, con
--          los bancarizados que ya salen por flg_clean 99 adentro. La referencia es
--          nodos.csv: 10,591 de 18,664 son plineros en la poblacion IBK del nodo,
--          o sea 56.7 por ciento. Se parte por entidad y por bucket de flg_clean, y
--          se mide en el mes contra la ventana u3m que es la que usa el nodo
-- ============================================================================
WITH po AS (
    SELECT codmes_mrm, id_value, entidad, flg_clean,
           date_format(date_add('month', -3, date_parse(codmes_mrm, '%Y%m')), '%Y%m')   AS m03,
           date_format(date_add('month', -1, date_parse(codmes_mrm, '%Y%m')), '%Y%m')   AS m01
    FROM disc_model_owner.ds_adm_vcnbank_tc_cal
    WHERE codmes_mrm BETWEEN '202410' AND '202504'
),
a AS (
    SELECT DISTINCT p.cif_key, p.p_codmes
    FROM e_perm_aws.t_agg_retail_user_trx_plin p
    INNER JOIN (SELECT DISTINCT id_value FROM po) k ON k.id_value = CAST(p.cif_key AS VARCHAR)
    WHERE p.p_codmes BETWEEN '202407' AND '202504'
),
x AS (
    SELECT po.codmes_mrm,
           po.id_value,
           po.entidad,
           po.flg_clean,
           max(CASE WHEN a.p_codmes = po.codmes_mrm THEN 1 ELSE 0 END)                  AS plin_m0,
           max(CASE WHEN a.p_codmes BETWEEN po.m03 AND po.m01 THEN 1 ELSE 0 END)        AS plin_u3m,
           max(CASE WHEN a.p_codmes BETWEEN po.m03 AND po.codmes_mrm THEN 1 ELSE 0 END) AS plin_u3m_con_m0
    FROM po
    LEFT JOIN a ON a.cif_key = po.id_value AND a.p_codmes BETWEEN po.m03 AND po.codmes_mrm
    GROUP BY po.codmes_mrm, po.id_value, po.entidad, po.flg_clean
)
SELECT entidad,
       CASE WHEN flg_clean = 99 THEN '3.fuera de alcance'
            WHEN flg_clean = 1  THEN '1.clean'
            ELSE                     '2.dirty' END                                      AS bucket,
       count(*)                                                                         AS n,
       round(100.0 * avg(CAST(plin_m0         AS DOUBLE)), 3)                           AS pct_plin_mes,
       round(100.0 * avg(CAST(plin_u3m        AS DOUBLE)), 3)                           AS pct_plin_u3m,
       round(100.0 * avg(CAST(plin_u3m_con_m0 AS DOUBLE)), 3)                           AS pct_plin_u3m_con_m0
FROM x
GROUP BY entidad,
         CASE WHEN flg_clean = 99 THEN '3.fuera de alcance'
              WHEN flg_clean = 1  THEN '1.clean'
              ELSE                     '2.dirty' END
ORDER BY entidad, bucket
LIMIT 40
