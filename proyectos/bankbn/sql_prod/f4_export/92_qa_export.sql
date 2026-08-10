-- 92_qa_export.sql | reconcilia el export contra la fuente. Las dos filas deben ser identicas en todas las columnas
SELECT origen,
       count(1)                                             AS filas,
       count(DISTINCT CAST(codmes AS VARCHAR))              AS meses,
       min(CAST(codmes AS VARCHAR))                         AS mes_min,
       max(CAST(codmes AS VARCHAR))                         AS mes_max,
       sum(CASE WHEN flg_clean = 1 THEN 1 ELSE 0 END)       AS n_clean,
       sum(CASE WHEN flg_clean = 0 THEN 1 ELSE 0 END)       AS n_dirty,
       sum(CASE WHEN flg_calib = 1 THEN 1 ELSE 0 END)       AS n_calib,
       sum(CASE WHEN entidad = 'IBK' THEN 1 ELSE 0 END)     AS n_ibk,
       count(target_12m)                                    AS con_target_12m,
       count(pd_raw)                                        AS con_pd_raw
FROM (
    SELECT 'A_EXPORT' AS origen, codmes, flg_clean, flg_calib, entidad, target_12m, pd_raw
    FROM disc_model_owner.ds_adm_bpe_bankbn_cal_export
    UNION ALL
    SELECT 'B_FUENTE', codmes, flg_clean, flg_calib, entidad, target_12m, pd_raw
    FROM disc_model_owner.ds_adm_bpe_bankbn_cal
    WHERE flg_clean IN (0, 1)
) u
GROUP BY origen
ORDER BY origen
