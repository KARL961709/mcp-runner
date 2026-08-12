-- 65_fct_altas_perfil.sql | perfil de t_rsk_fct_altas_tc en un mes reciente. Confirma que es alta de IBK y no del sistema, y dimensiona los ejes candidatos a segmentacion que esta tabla aporta y ninguna otra tiene
SELECT c.eje,
       c.valor,
       count(*)                                                                  AS n,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY c.eje), 2)      AS pct_en_eje
FROM e_perm_aws.t_rsk_fct_altas_tc t
CROSS JOIN UNNEST(ARRAY['1.tipo_reporte', '2.nivel_buro', '3.situacion_laboral', '4.canal',
                        '5.zona_riesgo_orig', '6.tipo_cliente_agrupado', '7.marca_informal'],
                  ARRAY[CAST(t.tipo_reporte AS VARCHAR), CAST(t.nivel_buro AS VARCHAR),
                        CAST(t.situacion_laboral AS VARCHAR), CAST(t.canal AS VARCHAR),
                        CAST(t.zona_riesgo_orig AS VARCHAR), CAST(t.tipo_cliente_agrupado AS VARCHAR),
                        CAST(t.marca_informal AS VARCHAR)])
     AS c (eje, valor)
WHERE t.p_codmes = '202404'
GROUP BY c.eje, c.valor
ORDER BY c.eje, n DESC
LIMIT 90
