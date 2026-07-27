-- eq_01_po_vs_universo.sql | codigo de entidad NORMALIZADO a entero: el universo lo guarda sin ceros. equivalencia de la PO contra el universo del desarrollador por mes: poblacion y atribucion de entidad
SELECT cm                                                                       AS codmes,
       sum(CASE WHEN nk IS NOT NULL THEN 1 ELSE 0 END)                          AS n_nuestro,
       sum(CASE WHEN sk IS NOT NULL THEN 1 ELSE 0 END)                          AS n_suyo,
       sum(CASE WHEN nk IS NOT NULL AND sk IS NOT NULL THEN 1 ELSE 0 END)       AS n_comun,
       sum(CASE WHEN sk IS NULL THEN 1 ELSE 0 END)                              AS solo_nuestro,
       sum(CASE WHEN nk IS NULL THEN 1 ELSE 0 END)                              AS solo_suyo,
       sum(CASE WHEN nk IS NOT NULL AND sk IS NOT NULL AND n_ent <> s_ent THEN 1 ELSE 0 END) AS ent_distinta,
       sum(CASE WHEN nk IS NOT NULL AND sk IS NOT NULL AND n_ent = 2 AND s_ent <> 2 THEN 1 ELSE 0 END) AS gana_ibk_nuestro,
       sum(CASE WHEN nk IS NOT NULL AND sk IS NOT NULL AND s_ent = 2 AND n_ent <> 2 THEN 1 ELSE 0 END) AS gana_ibk_suyo
FROM (
    SELECT COALESCE(n.cm, s.cm) AS cm,
           n.key_value AS nk, s.key_value AS sk,
           n.ent AS n_ent, s.ent AS s_ent
    FROM (
        SELECT CAST(codmes AS VARCHAR) AS cm, CAST(tip_doc AS VARCHAR) AS td,
               CAST(key_value AS VARCHAR) AS key_value, CAST(TRIM(CAST(cod_instit_financiera AS VARCHAR)) AS INT) AS ent
        FROM disc_model_owner.ds_adm_bpe_bankbn_po
        WHERE CAST(codmes AS VARCHAR) BETWEEN '202301' AND '202507'
    ) n
    FULL OUTER JOIN (
        SELECT CAST(codmes AS VARCHAR) AS cm, CAST(tip_doc AS VARCHAR) AS td,
               CAST(key_value AS VARCHAR) AS key_value, CAST(TRIM(CAST(cod_instit_financiera AS VARCHAR)) AS INT) AS ent
        FROM disc_riesgos.universo_bank_bpe_202301_202507_uni
    ) s
      ON n.cm = s.cm AND n.td = s.td AND n.key_value = s.key_value
) j
GROUP BY cm
ORDER BY cm
