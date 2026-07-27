-- d1_motivo_del_dirty.sql | por que es dirty: atribucion EXCLUSIVA (unico motivo) vs multiple. u4 daba conteos solapados
SELECT grupo,
       CASE WHEN n_filtros = 1 THEN motivo_unico
            ELSE '9_MULTIPLE_' || CAST(least(n_filtros, 4) AS VARCHAR) || CASE WHEN n_filtros > 4 THEN '_o_mas' ELSE '' END
       END                                                        AS motivo,
       count(1)                                                   AS n,
       round(100.0 * count(1) / sum(count(1)) OVER (PARTITION BY grupo), 2) AS pct_del_dirty,
       sum(tgt)                                                   AS malos,
       round(100.0 * sum(tgt) / count(1), 2)                      AS rd_pct
FROM (
    SELECT CASE WHEN entidad = 'IBK' THEN '1_IBK' ELSE '2_SSFF' END AS grupo,
           CAST(target_12m AS BIGINT) AS tgt,
           filtro_castigado_org + filtro_judicial_org + filtro_reest_org + filtro_refin_org
         + filtro_clasif_no_normal + filtro_diasatraso_org + filtro_sbs_no_normal_1um + filtro_novig_1um
         + filtro_edad_titular + filtro_edad_rrll + filtro_novig_12um + filtro_rrll_cast_12um AS n_filtros,
           CASE WHEN filtro_castigado_org     = 1 THEN '1_castigado_org'
                WHEN filtro_judicial_org      = 1 THEN '2_judicial_org'
                WHEN filtro_reest_org         = 1 THEN '3_reest_org'
                WHEN filtro_refin_org         = 1 THEN '4_refin_org'
                WHEN filtro_clasif_no_normal  = 1 THEN '5_clasif_no_normal'
                WHEN filtro_diasatraso_org    = 1 THEN '6_diasatraso_org'
                WHEN filtro_sbs_no_normal_1um = 1 THEN '7_sbs_no_normal_1um'
                WHEN filtro_novig_1um         = 1 THEN '8_novig_1um'
                WHEN filtro_edad_titular      = 1 THEN 'A_edad_titular'
                WHEN filtro_edad_rrll         = 1 THEN 'B_edad_rrll'
                WHEN filtro_novig_12um        = 1 THEN 'C_novig_12um'
                WHEN filtro_rrll_cast_12um    = 1 THEN 'D_rrll_cast_12um' END AS motivo_unico
    FROM disc_model_owner.ds_adm_bpe_bankbn_cal
    WHERE CAST(codmes AS VARCHAR) BETWEEN '202206' AND '202506'
      AND flg_clean = 0
      AND target_12m IS NOT NULL
) z
GROUP BY grupo,
         CASE WHEN n_filtros = 1 THEN motivo_unico
              ELSE '9_MULTIPLE_' || CAST(least(n_filtros, 4) AS VARCHAR) || CASE WHEN n_filtros > 4 THEN '_o_mas' ELSE '' END
         END
ORDER BY grupo, n DESC
