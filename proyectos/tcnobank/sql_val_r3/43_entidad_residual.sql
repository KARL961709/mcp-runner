-- 43_entidad_residual.sql | tasa observada contra pd cruda por entidad y tramo de score nuevo, para separar si la brecha entre entidades ya la explica el score o queda efecto residual que obligue a segmentar
SELECT entidad,
       CASE WHEN scr_nuevo < 800 THEN '1.<800'
            WHEN scr_nuevo < 880 THEN '2.800-879'
            WHEN scr_nuevo < 940 THEN '3.880-939'
            ELSE '4.940+' END                                         AS tramo_scr_nuevo,
       count(*)                                                       AS n,
       round(100.0 * avg(CAST(target_12m AS DOUBLE)), 3)              AS rd_pub,
       round(100.0 * avg(CAST(target_12m_full AS DOUBLE)), 3)         AS rd_full,
       round(100.0 * avg(pd_raw), 3)                                  AS pd_raw,
       round(avg(CAST(target_12m AS DOUBLE)) / nullif(avg(pd_raw), 0), 4) AS ratio_obs_raw
FROM disc_model_owner.ds_tcnobank_calib_v1
WHERE flg_maduro = 1
  AND prelacion_00m = 1
  AND target_12m IS NOT NULL
  AND scr_nuevo IS NOT NULL
GROUP BY entidad, 2
HAVING count(*) >= 200
ORDER BY entidad, 2
