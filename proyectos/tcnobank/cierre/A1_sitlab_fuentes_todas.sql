-- A1_sitlab_fuentes_todas.sql | lista COMPLETA de fuentes para sit_lab DEPENDIENTE, sin el LIMIT que trunco la 99. Interesa confirmar que existen SUSALUD e INFERIDO_IND_MVP, las dos que la logica nueva agrega a la exclusion, y cuanto volumen mueven. Separa NULL de string vacio porque se comportan distinto en el IN
SELECT coalesce(fuente, '<<NULL>>')                                             AS fuente,
       CASE WHEN fuente IS NULL THEN 'NULL'
            WHEN trim(fuente) = '' THEN 'VACIO'
            ELSE 'CON VALOR' END                                                AS tipo_valor,
       CASE WHEN fuente IN ('INFERIDO', 'EXPERIAN') THEN 'excluida vieja y nueva'
            WHEN fuente IN ('SUSALUD', 'INFERIDO_IND_MVP') THEN 'excluida SOLO nueva'
            ELSE 'valida en ambas' END                                          AS trato,
       count(*)                                                                 AS n,
       count(DISTINCT substr(p_fecinformacion, 1, 6))                           AS meses,
       min(p_fecinformacion)                                                    AS fec_min,
       max(p_fecinformacion)                                                    AS fec_max
FROM e_perm_aws.ds_rtd_rskvol_cas_ingr_ir
WHERE sit_lab = 'DEPENDIENTE'
GROUP BY fuente
ORDER BY n DESC
LIMIT 60
