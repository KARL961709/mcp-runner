-- qa_10_desempate_ibk.sql | A30 el desempate de entidad de alta gana IBK: reconstruye los candidatos desde tmp_altas_t1..t6 y los cruza contra el ganador que quedo en la PO | n_viol debe ser 0
WITH altas AS (
    SELECT CAST(codmes AS VARCHAR) AS cm, tip_doc, key_value, CAST(cod_instit_financiera AS VARCHAR) AS ent FROM disc_model_owner.ds_adm_bpe_bankbn_tmp_altas_t1 WHERE alta2 = 1
    UNION ALL
    SELECT CAST(codmes AS VARCHAR), tip_doc, key_value, CAST(cod_instit_financiera AS VARCHAR) FROM disc_model_owner.ds_adm_bpe_bankbn_tmp_altas_t2 WHERE alta2 = 1
    UNION ALL
    SELECT CAST(codmes AS VARCHAR), tip_doc, key_value, CAST(cod_instit_financiera AS VARCHAR) FROM disc_model_owner.ds_adm_bpe_bankbn_tmp_altas_t3 WHERE alta2 = 1
    UNION ALL
    SELECT CAST(codmes AS VARCHAR), tip_doc, key_value, CAST(cod_instit_financiera AS VARCHAR) FROM disc_model_owner.ds_adm_bpe_bankbn_tmp_altas_t4 WHERE alta2 = 1
    UNION ALL
    SELECT CAST(codmes AS VARCHAR), tip_doc, key_value, CAST(cod_instit_financiera AS VARCHAR) FROM disc_model_owner.ds_adm_bpe_bankbn_tmp_altas_t5 WHERE alta2 = 1
    UNION ALL
    SELECT CAST(codmes AS VARCHAR), tip_doc, key_value, CAST(cod_instit_financiera AS VARCHAR) FROM disc_model_owner.ds_adm_bpe_bankbn_tmp_altas_t6 WHERE alta2 = 1
),
cand AS (
    SELECT cm, tip_doc, key_value,
           count(DISTINCT ent) AS n_ent,
           max(CASE WHEN ent = '00002' THEN 1 ELSE 0 END) AS c_ibk,
           max(CASE WHEN ent = '00001' THEN 1 ELSE 0 END) AS c_bcp
    FROM altas
    GROUP BY 1, 2, 3
),
j AS (
    SELECT
        CASE WHEN c.n_ent IS NULL THEN 1 ELSE 0 END AS sin_cand,
        CASE WHEN COALESCE(c.n_ent, 0) > 1 THEN 1 ELSE 0 END AS multi,
        COALESCE(c.c_ibk, 0) AS c_ibk,
        COALESCE(c.c_bcp, 0) AS c_bcp,
        COALESCE(CAST(p.cod_instit_financiera AS VARCHAR), 'NULO') AS gana
    FROM disc_model_owner.ds_adm_bpe_bankbn_po p
    LEFT JOIN cand c
      ON CAST(p.codmes AS VARCHAR) = c.cm AND p.tip_doc = c.tip_doc AND p.key_value = c.key_value
),
a AS (
    SELECT
        CAST(count(1) AS BIGINT) AS n_po,
        CAST(sum(sin_cand) AS BIGINT) AS n_sincand,
        CAST(sum(multi) AS BIGINT) AS n_multi,
        CAST(sum(c_ibk) AS BIGINT) AS n_candibk,
        CAST(sum(CASE WHEN c_ibk = 1 AND gana = '00002' THEN 1 ELSE 0 END) AS BIGINT) AS n_ibkgana,
        CAST(sum(CASE WHEN c_ibk = 1 AND gana <> '00002' THEN 1 ELSE 0 END) AS BIGINT) AS n_ibkpierde,
        CAST(sum(CASE WHEN c_ibk = 1 AND c_bcp = 1 THEN 1 ELSE 0 END) AS BIGINT) AS n_duelo,
        CAST(sum(CASE WHEN c_ibk = 1 AND c_bcp = 1 AND gana = '00002' THEN 1 ELSE 0 END) AS BIGINT) AS n_duelo_ibk,
        CAST(sum(CASE WHEN c_ibk = 1 AND c_bcp = 1 AND gana = '00001' THEN 1 ELSE 0 END) AS BIGINT) AS n_duelo_bcp
    FROM j
)
SELECT
    t.orden,
    t.chk,
    t.n_viol,
    t.n_magnitud,
    t.n_base,
    round(100e0 * t.n_magnitud / nullif(t.n_base, 0), 4) AS pct_sobre_base,
    CASE WHEN t.n_viol = 0 THEN 'OK' ELSE 'REVISAR' END AS veredicto
FROM a
CROSS JOIN UNNEST(
    ARRAY[
         1,
         2,
         3,
         4,
         5,
         6,
         7,
         8,
         9
    ],
    ARRAY[
         'A01 OBS filas de la PO',
         'A02 filas de PO sin candidato en tmp_altas sanity del join',
         'A03 OBS cliente-mes multientidad referencia m07 1.84 pct',
         'A04 OBS cliente-mes con IBK entre los candidatos',
         'A05 IBK candidato y gana IBK debe ser 100 pct de A04',
         'A06 IBK candidato y PIERDE viola A30',
         'A07 OBS duelo IBK contra BCP',
         'A08 duelo ganado por IBK debe ser 100 pct de A07',
         'A09 duelo ganado por BCP firma del CTAS viejo'
    ],
    ARRAY[
         CAST(0 AS BIGINT),
         a.n_sincand,
         CAST(0 AS BIGINT),
         CAST(0 AS BIGINT),
         CAST(CASE WHEN a.n_candibk > 0 AND a.n_ibkgana <> a.n_candibk THEN 1 ELSE 0 END AS BIGINT),
         a.n_ibkpierde,
         CAST(0 AS BIGINT),
         CAST(CASE WHEN a.n_duelo > 0 AND a.n_duelo_ibk <> a.n_duelo THEN 1 ELSE 0 END AS BIGINT),
         a.n_duelo_bcp
    ],
    ARRAY[
         a.n_po,
         a.n_sincand,
         a.n_multi,
         a.n_candibk,
         a.n_ibkgana,
         a.n_ibkpierde,
         a.n_duelo,
         a.n_duelo_ibk,
         a.n_duelo_bcp
    ],
    ARRAY[
         a.n_po,
         a.n_po,
         a.n_po,
         a.n_po,
         a.n_candibk,
         a.n_candibk,
         a.n_po,
         a.n_duelo,
         a.n_duelo
    ]
) AS t (orden, chk, n_viol, n_magnitud, n_base)
ORDER BY t.orden
