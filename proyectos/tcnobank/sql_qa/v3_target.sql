-- v3_target.sql | G3. El target tiene que ser NULL cuando no es observable, nunca 0. Y las cuatro variantes tienen
-- que ordenarse: corr no puede tener menos malos que la publicada, porque solo agrega los defaults que la cascada de
-- produccion perdia por evaluar la zona gris antes del evento.
SELECT 'G3'                                                                    AS gate,
       chk, n_viol, n_magnitud,
       CASE WHEN n_viol = 0 THEN 'PASS' ELSE 'FAIL' END                        AS veredicto
FROM (
    SELECT 'inmaduros con target no nulo'                                      AS chk,
           sum(CASE WHEN falla_madurez = 1 AND target_12m IS NOT NULL THEN 1 ELSE 0 END) AS n_viol,
           sum(CASE WHEN falla_madurez = 1 THEN 1 ELSE 0 END)                  AS n_magnitud
    FROM disc_model_owner.ds_adm_tcnb_cal
    UNION ALL
    SELECT 'target_12m = 1 que corr no marca malo',
           sum(CASE WHEN target_12m = 1 AND coalesce(target_12m_corr, -1) <> 1 THEN 1 ELSE 0 END),
           sum(CASE WHEN target_12m = 1 THEN 1 ELSE 0 END)
    FROM disc_model_owner.ds_adm_tcnb_cal
    UNION ALL
    SELECT 'bueno con mora futura mayor a 60',
           sum(CASE WHEN target_12m_corr = 0 AND max_dm_fut > 60 THEN 1 ELSE 0 END),
           sum(CASE WHEN target_12m_corr = 0 THEN 1 ELSE 0 END)
    FROM disc_model_owner.ds_adm_tcnb_cal
    UNION ALL
    SELECT 'bueno con evento duro a futuro',
           sum(CASE WHEN target_12m_corr = 0 AND f_evento_fut = 1 THEN 1 ELSE 0 END),
           sum(CASE WHEN target_12m_corr = 0 THEN 1 ELSE 0 END)
    FROM disc_model_owner.ds_adm_tcnb_cal
    UNION ALL
    SELECT 'missing_12 fuera de 0 a 12',
           sum(CASE WHEN missing_12 < 0 OR missing_12 > 12 OR missing_12 IS NULL THEN 1 ELSE 0 END),
           count(*)
    FROM disc_model_owner.ds_adm_tcnb_cal
) y
