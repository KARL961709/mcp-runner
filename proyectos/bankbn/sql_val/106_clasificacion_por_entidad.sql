-- 106_clasificacion_por_entidad.sql | IBK clasifica mas conservador que sus pares? A igual clasificacion SBS en m-2, la RD deberia ser MENOR en IBK si su umbral es mas exigente. Es el mismo control de los quintiles de score, aplicado a la clasificacion
SELECT CASE WHEN CAST(TRIM(CAST(cod_instit_financiera AS VARCHAR)) AS INT) = 2
            THEN 'A_IBK' ELSE 'B_RESTO_TOP4' END                                AS grupo,
       COALESCE(clasificacion_m2, '(NULO)')                                     AS clasif_m2,
       count(1)                                                                 AS n,
       round(100.0 * count(1)
             / sum(count(1)) OVER (PARTITION BY CASE WHEN CAST(TRIM(CAST(cod_instit_financiera AS VARCHAR)) AS INT) = 2
                                                    THEN 'A_IBK' ELSE 'B_RESTO_TOP4' END), 3) AS pct_del_grupo,
       count(target_12m)                                                        AS n_maduro,
       round(100.0 * avg(TRY_CAST(target_12m AS DOUBLE)), 3)                    AS rd12_pct,
       round(100.0 * avg(TRY_CAST(dias_atraso_12m AS DOUBLE)), 1)               AS atraso_medio,
       round(100.0 * avg(CASE WHEN TRY_CAST(dm_org_m2 AS DOUBLE) > 0 THEN 1.0 ELSE 0.0 END), 3) AS con_atraso_m2_pct
FROM disc_model_owner.ds_adm_bpe_bankbn_mad
WHERE CAST(TRIM(CAST(cod_instit_financiera AS VARCHAR)) AS INT) IN (1, 2, 4, 6)
  AND codmes BETWEEN '202206' AND '202506'
GROUP BY CASE WHEN CAST(TRIM(CAST(cod_instit_financiera AS VARCHAR)) AS INT) = 2
              THEN 'A_IBK' ELSE 'B_RESTO_TOP4' END,
         COALESCE(clasificacion_m2, '(NULO)')
ORDER BY grupo, clasif_m2
