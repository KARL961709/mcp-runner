-- 91_funnel_aislado.sql | E3/E4 con R4: n de cada filtro medido sobre su expr_ref AISLADO y sobre la base completa, no sobre la cascada. Los n publicados en dsc_flg_malo_12m son residuales: solo el primero de la cascada mide su propio filtro. El target se reconstruye por separado para poder leer el bad-rate DENTRO de cada grupo excluido, que es lo que dice si el filtro saca malos o buenos
SELECT f.filtro,
       sum(f.dispara)                                                                  AS n_aislado,
       round(100.0 * sum(f.dispara) / count(*), 4)                                     AS pct_universo,
       sum(CASE WHEN f.dispara = 1 AND t.evaluable = 1 THEN 1 ELSE 0 END)              AS n_evaluable,
       sum(CASE WHEN f.dispara = 1 AND t.malo = 1 THEN 1 ELSE 0 END)                   AS n_malo,
       round(100.0 * sum(CASE WHEN f.dispara = 1 AND t.malo = 1 THEN 1 ELSE 0 END)
             / nullif(sum(CASE WHEN f.dispara = 1 AND t.evaluable = 1 THEN 1 ELSE 0 END), 0), 3)
                                                                                       AS bad_rate,
       sum(CASE WHEN f.dispara = 1 AND t.cascada = f.filtro THEN 1 ELSE 0 END)         AS n_en_cascada
FROM (
    SELECT dsc_flg_malo_12m                                                            AS cascada,
           coalesce(flg_cstg_00m, 0)                                                   AS f_cast_ori,
           coalesce(flg_jdcl_00m, 0)                                                   AS f_jud_ori,
           coalesce(flg_rfnc_00m, 0)                                                   AS f_ref_ori,
           coalesce(flg_rstr_00m, 0)                                                   AS f_ree_ori,
           CASE WHEN coalesce(flg_malo_orig, 0) = 1
                 AND coalesce(flg_cstg_00m, 0) = 0 AND coalesce(flg_jdcl_00m, 0) = 0
                 AND coalesce(flg_rfnc_00m, 0) = 0 AND coalesce(flg_rstr_00m, 0) = 0
                THEN 1 ELSE 0 END                                                      AS f_malo_ori,
           CASE WHEN dim.cod IS NULL THEN NULL
                WHEN dim.cod NOT IN ('00001', '00002', '00004', '00006', '00142')
                THEN 1 ELSE 0 END                                                      AS f_entidades,
           CASE WHEN max_dm_12m > 60 THEN 1 ELSE 0 END                                 AS f_dm60,
           CASE WHEN max_dm_12m BETWEEN 9 AND 60 THEN 1 ELSE 0 END                     AS f_indeterm,
           CASE WHEN coalesce(flg_cstg_12m, 0) = 1 OR coalesce(flg_jdcl_12m, 0) = 1
                  OR coalesce(flg_rfnc_12m, 0) = 1 OR coalesce(flg_rstr_12m, 0) = 1
                THEN 1 ELSE 0 END                                                      AS f_evento_fut,
           CASE WHEN (CASE WHEN nro_dm_m01 IS NULL THEN 1 ELSE 0 END)
                   + (CASE WHEN nro_dm_m02 IS NULL THEN 1 ELSE 0 END)
                   + (CASE WHEN nro_dm_m03 IS NULL THEN 1 ELSE 0 END)
                   + (CASE WHEN nro_dm_m04 IS NULL THEN 1 ELSE 0 END)
                   + (CASE WHEN nro_dm_m05 IS NULL THEN 1 ELSE 0 END)
                   + (CASE WHEN nro_dm_m06 IS NULL THEN 1 ELSE 0 END)
                   + (CASE WHEN nro_dm_m07 IS NULL THEN 1 ELSE 0 END)
                   + (CASE WHEN nro_dm_m08 IS NULL THEN 1 ELSE 0 END)
                   + (CASE WHEN nro_dm_m09 IS NULL THEN 1 ELSE 0 END)
                   + (CASE WHEN nro_dm_m10 IS NULL THEN 1 ELSE 0 END)
                   + (CASE WHEN nro_dm_m11 IS NULL THEN 1 ELSE 0 END)
                   + (CASE WHEN nro_dm_m12 IS NULL THEN 1 ELSE 0 END) = 12
                THEN 1 ELSE 0 END                                                      AS f_uncashed,
           CASE WHEN (CASE WHEN nro_dm_m01 IS NULL THEN 1 ELSE 0 END)
                   + (CASE WHEN nro_dm_m02 IS NULL THEN 1 ELSE 0 END)
                   + (CASE WHEN nro_dm_m03 IS NULL THEN 1 ELSE 0 END)
                   + (CASE WHEN nro_dm_m04 IS NULL THEN 1 ELSE 0 END)
                   + (CASE WHEN nro_dm_m05 IS NULL THEN 1 ELSE 0 END)
                   + (CASE WHEN nro_dm_m06 IS NULL THEN 1 ELSE 0 END)
                   + (CASE WHEN nro_dm_m07 IS NULL THEN 1 ELSE 0 END)
                   + (CASE WHEN nro_dm_m08 IS NULL THEN 1 ELSE 0 END)
                   + (CASE WHEN nro_dm_m09 IS NULL THEN 1 ELSE 0 END)
                   + (CASE WHEN nro_dm_m10 IS NULL THEN 1 ELSE 0 END)
                   + (CASE WHEN nro_dm_m11 IS NULL THEN 1 ELSE 0 END)
                   + (CASE WHEN nro_dm_m12 IS NULL THEN 1 ELSE 0 END) > 6
                THEN 1 ELSE 0 END                                                      AS f_insuf,
           CASE WHEN max_dm_12m > 60
                  OR coalesce(flg_cstg_12m, 0) = 1 OR coalesce(flg_jdcl_12m, 0) = 1
                  OR coalesce(flg_rfnc_12m, 0) = 1 OR coalesce(flg_rstr_12m, 0) = 1
                THEN 1 ELSE 0 END                                                      AS malo,
           CASE WHEN max_dm_12m > 60
                  OR coalesce(flg_cstg_12m, 0) = 1 OR coalesce(flg_jdcl_12m, 0) = 1
                  OR coalesce(flg_rfnc_12m, 0) = 1 OR coalesce(flg_rstr_12m, 0) = 1
                  OR max_dm_12m <= 8
                THEN 1 ELSE 0 END                                                      AS evaluable
    FROM e_perm_aws.ds_flg_admtcnobk1_rsk a
    LEFT JOIN (
        SELECT nombre_instit_financiera,
               min(ltrim(rtrim(cod_instit_financiera))) AS cod
        FROM e_perm_aws.t_dim_inst_fin_rsk
        GROUP BY nombre_instit_financiera
    ) dim
      ON a.nombre_instit_financiera = dim.nombre_instit_financiera
) t
CROSS JOIN UNNEST(
    ARRAY['03.CASTIGADOS EN EL ORIGEN', '04.JUDICIAL EN EL ORIGEN',
          '05.REFINANCIADOS EN EL ORIGEN', '06.RESTRUCTURADOS EN EL ORIGEN',
          '07.MALOS EN EL ORIGEN', '14.ENTIDADES',
          '16.UNCASHED', '17.INSUFICIENTE', '18.INDETERMINADO',
          '21.MALO por mora', '21.MALO por evento futuro'],
    ARRAY[t.f_cast_ori, t.f_jud_ori, t.f_ref_ori, t.f_ree_ori, t.f_malo_ori, t.f_entidades,
          t.f_uncashed, t.f_insuf, t.f_indeterm, t.f_dm60, t.f_evento_fut]
) AS f (filtro, dispara)
GROUP BY f.filtro
ORDER BY n_aislado DESC
