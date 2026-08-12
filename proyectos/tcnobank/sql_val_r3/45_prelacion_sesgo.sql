-- 45_prelacion_sesgo.sql | mide cuanto infla la tasa de malos elegir la fila del cliente con prelacion_12m, que ordena por el target y por tanto se queda con la entidad donde el cliente resulto malo, frente a prelacion_00m que no mira el resultado
SELECT c.criterio,
       count(*)                                                      AS n,
       sum(c.target_12m)                                             AS n_malo,
       round(100.0 * avg(CAST(c.target_12m AS DOUBLE)), 4)           AS rd_pub,
       round(100.0 * avg(CAST(c.target_12m_corr AS DOUBLE)), 4)      AS rd_corr,
       round(100.0 * avg(c.pd_raw), 4)                               AS pd_raw,
       round(avg(c.scr_nuevo), 1)                                    AS scr_nuevo_medio
FROM (
    SELECT '1.prelacion_00m (sin look-ahead)' AS criterio, target_12m, target_12m_corr, pd_raw, scr_nuevo
    FROM disc_model_owner.ds_tcnobank_calib_v1
    WHERE flg_maduro = 1 AND prelacion_00m = 1 AND target_12m IS NOT NULL
    UNION ALL
    SELECT '2.prelacion_12m (ordena por target)' AS criterio, target_12m, target_12m_corr, pd_raw, scr_nuevo
    FROM disc_model_owner.ds_tcnobank_calib_v1
    WHERE flg_maduro = 1 AND prelacion_12m = 1 AND target_12m IS NOT NULL
    UNION ALL
    SELECT '3.sin dedup (todas las filas)' AS criterio, target_12m, target_12m_corr, pd_raw, scr_nuevo
    FROM disc_model_owner.ds_tcnobank_calib_v1
    WHERE flg_maduro = 1 AND target_12m IS NOT NULL
) c
GROUP BY c.criterio
ORDER BY c.criterio
