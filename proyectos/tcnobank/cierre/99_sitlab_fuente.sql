-- 99_sitlab_fuente.sql | de donde sale el DEP_VAL. En el VARS el segmento nace de la cascada de ingresos: DEPENDIENTE con fuente distinta de INFERIDO y EXPERIAN es 1.DEP_VAL, todo lo demas cae a MIXTO o INDEPENDIENTE. Interesa la profundidad de esa tabla y el reparto de sit_lab por fuente, porque el corte del segmento depende de que fuente valido el ingreso
SELECT substr(p_fecinformacion, 1, 4)                                                  AS anio,
       coalesce(sit_lab, 'NULL')                                                       AS sit_lab,
       coalesce(fuente, 'NULL')                                                        AS fuente,
       CASE WHEN sit_lab = 'DEPENDIENTE' AND fuente NOT IN ('INFERIDO', 'EXPERIAN') THEN '1.DEP_VAL'
            WHEN sit_lab = 'DEPENDIENTE' THEN '3.MIXTO'
            WHEN sit_lab = 'MIXTO' THEN '3.MIXTO'
            ELSE '4.INDEPENDIENTE' END                                                 AS sitlab_derivado,
       count(*)                                                                        AS n,
       count(DISTINCT periodo)                                                         AS n_periodos,
       min(p_fecinformacion)                                                           AS fec_min,
       max(p_fecinformacion)                                                           AS fec_max
FROM e_perm_aws.ds_rtd_rskvol_cas_ingr_ir
GROUP BY substr(p_fecinformacion, 1, 4), sit_lab, fuente
ORDER BY anio, n DESC
LIMIT 90
