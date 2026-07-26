-- 2t3_d_mad_rl_uni.sql | TRAMO T3 | codmes 202306-202311 | CREATE (tmp descartable por tramo)
-- Sin literales de mes: hereda el acotado de tmp_mad_rcc. Vigencia PIT fec_vigencia <= codmes.
-- Generado por gen_tramos.py: el texto es identico entre tramos salvo los literales de mes,
-- por eso la proyeccion del INSERT INTO coincide posicionalmente con la del CREATE TABLE.
-- 20b. Representantes legales vigentes (SUNAT rep_legal PIT) -> disc_model_owner.ds_adm_bpe_bankbn_tmp_mad_rl_uni
--  1. Etapa 2 de 7. Ex CTE uni_rl. Se materializa porque el 20_target lo referenciaba 4 veces
--     (nacimiento_rl, uni_rl_key, fea_rcc_rl, rcc_rl, rcc_rl_titular) y Trino lo re-inlineaba entero.
--  2. uni_mad = grano (codmes, tip_doc, key_value) de 20a. Vigencia point-in-time: fec_vigencia <= codmes.
--  3. Grano de salida: (codmes, tip_doc, key_value, nrodoc_rl, tipdoc_rl).
CREATE TABLE disc_model_owner.ds_adm_bpe_bankbn_tmp_mad_rl_uni AS
SELECT
    b.codmes,
    b.key_value,
    b.tip_doc,
    a.key_value AS nrodoc_rl,
    a.tip_doc   AS tipdoc_rl
FROM e_perm_aws.t_mst_rep_legal_sunat_rsk a
INNER JOIN (
    SELECT DISTINCT codmes, tip_doc, key_value
    FROM disc_model_owner.ds_adm_bpe_bankbn_tmp_mad_rcc
) b
    ON a.ruc_value = b.key_value
   AND cast(date_format(date_parse(cast(a.fec_vigencia AS varchar),'%Y-%m-%d'), '%Y%m') AS int) <= cast(b.codmes AS int)
GROUP BY b.codmes, b.key_value, b.tip_doc, a.key_value, a.tip_doc
