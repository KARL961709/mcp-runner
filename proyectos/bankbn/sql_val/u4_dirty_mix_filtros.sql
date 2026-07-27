-- u4_dirty_mix_filtros.sql | que filtro domina el dirty en IBK vs SSFF: si la mezcla difiere, explica la inversion sin lente
SELECT t.filtro,
       t.n_ibk,
       round(100.0 * t.n_ibk / nullif(a.base_ibk, 0), 1)   AS pct_dirty_ibk,
       round(100.0 * t.m_ibk / nullif(t.n_ibk, 0), 2)      AS tasa_ibk,
       t.n_ssff,
       round(100.0 * t.n_ssff / nullif(a.base_ssff, 0), 1) AS pct_dirty_ssff,
       round(100.0 * t.m_ssff / nullif(t.n_ssff, 0), 2)    AS tasa_ssff
FROM (
    SELECT sum(ibk) AS base_ibk, sum(1 - ibk) AS base_ssff,
           sum(ibk * f01) AS n1i, sum(ibk * f01 * tgt) AS m1i, sum((1-ibk) * f01) AS n1s, sum((1-ibk) * f01 * tgt) AS m1s,
           sum(ibk * f02) AS n2i, sum(ibk * f02 * tgt) AS m2i, sum((1-ibk) * f02) AS n2s, sum((1-ibk) * f02 * tgt) AS m2s,
           sum(ibk * f03) AS n3i, sum(ibk * f03 * tgt) AS m3i, sum((1-ibk) * f03) AS n3s, sum((1-ibk) * f03 * tgt) AS m3s,
           sum(ibk * f04) AS n4i, sum(ibk * f04 * tgt) AS m4i, sum((1-ibk) * f04) AS n4s, sum((1-ibk) * f04 * tgt) AS m4s,
           sum(ibk * f05) AS n5i, sum(ibk * f05 * tgt) AS m5i, sum((1-ibk) * f05) AS n5s, sum((1-ibk) * f05 * tgt) AS m5s,
           sum(ibk * f06) AS n6i, sum(ibk * f06 * tgt) AS m6i, sum((1-ibk) * f06) AS n6s, sum((1-ibk) * f06 * tgt) AS m6s,
           sum(ibk * f07) AS n7i, sum(ibk * f07 * tgt) AS m7i, sum((1-ibk) * f07) AS n7s, sum((1-ibk) * f07 * tgt) AS m7s,
           sum(ibk * f08) AS n8i, sum(ibk * f08 * tgt) AS m8i, sum((1-ibk) * f08) AS n8s, sum((1-ibk) * f08 * tgt) AS m8s,
           sum(ibk * f09) AS n9i, sum(ibk * f09 * tgt) AS m9i, sum((1-ibk) * f09) AS n9s, sum((1-ibk) * f09 * tgt) AS m9s,
           sum(ibk * f10) AS n10i, sum(ibk * f10 * tgt) AS m10i, sum((1-ibk) * f10) AS n10s, sum((1-ibk) * f10 * tgt) AS m10s,
           sum(ibk * f11) AS n11i, sum(ibk * f11 * tgt) AS m11i, sum((1-ibk) * f11) AS n11s, sum((1-ibk) * f11 * tgt) AS m11s,
           sum(ibk * f12) AS n12i, sum(ibk * f12 * tgt) AS m12i, sum((1-ibk) * f12) AS n12s, sum((1-ibk) * f12 * tgt) AS m12s
    FROM (
        SELECT CASE WHEN entidad = 'IBK' THEN 1 ELSE 0 END AS ibk,
               CAST(target_12m AS BIGINT)                  AS tgt,
               filtro_castigado_org AS f01, filtro_judicial_org     AS f02,
               filtro_reest_org     AS f03, filtro_refin_org        AS f04,
               filtro_clasif_no_normal AS f05, filtro_diasatraso_org AS f06,
               filtro_sbs_no_normal_1um AS f07, filtro_novig_1um    AS f08,
               filtro_edad_titular  AS f09, filtro_edad_rrll        AS f10,
               filtro_novig_12um    AS f11, filtro_rrll_cast_12um   AS f12
        FROM disc_model_owner.ds_adm_bpe_bankbn_cal
        WHERE CAST(codmes AS VARCHAR) BETWEEN '202206' AND '202506'
          AND flg_clean = 0
          AND target_12m IS NOT NULL
    ) z
) a
CROSS JOIN UNNEST(
    ARRAY['castigado_org','judicial_org','reest_org','refin_org','clasif_no_normal','diasatraso_org',
          'sbs_no_normal_1um','novig_1um','edad_titular','edad_rrll','novig_12um','rrll_cast_12um'],
    ARRAY[a.n1i,a.n2i,a.n3i,a.n4i,a.n5i,a.n6i,a.n7i,a.n8i,a.n9i,a.n10i,a.n11i,a.n12i],
    ARRAY[a.m1i,a.m2i,a.m3i,a.m4i,a.m5i,a.m6i,a.m7i,a.m8i,a.m9i,a.m10i,a.m11i,a.m12i],
    ARRAY[a.n1s,a.n2s,a.n3s,a.n4s,a.n5s,a.n6s,a.n7s,a.n8s,a.n9s,a.n10s,a.n11s,a.n12s],
    ARRAY[a.m1s,a.m2s,a.m3s,a.m4s,a.m5s,a.m6s,a.m7s,a.m8s,a.m9s,a.m10s,a.m11s,a.m12s]
) AS t (filtro, n_ibk, m_ibk, n_ssff, m_ssff)
ORDER BY t.n_ibk DESC
