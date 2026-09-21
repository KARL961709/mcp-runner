-- ============================================================================
-- a20. Review del insumo ds_adm_pp_cdpp_cal partido IBK vs SS.FF x sub_producto (202311+).
--      Que trae cada segmento para poder extrapolar la calibracion a SS.FF:
--      cobertura de pd_raw, distribucion de nodo (blank / N1 / N2 / N3 -> ver si ya
--      esta la logica N3-por-ausencia), tipo_ingreso (DEP/NO_DEP/blank, feature interno
--      IBK), flg_clean (1/0/99) y cuantas entidades. Solo agregados.
-- ============================================================================
SELECT
    flg_ibk,
    sub_producto,
    COUNT(*) AS n,
    count(DISTINCT cod_instit_financiera) AS n_entidades,
    SUM(CASE WHEN pd_raw IS NOT NULL THEN 1 ELSE 0 END) AS n_pdraw,
    SUM(CASE WHEN nodo IS NULL OR nodo = '' THEN 1 ELSE 0 END) AS nodo_blank,
    SUM(CASE WHEN nodo = 'NODO 1' THEN 1 ELSE 0 END) AS nodo_1,
    SUM(CASE WHEN nodo = 'NODO 2' THEN 1 ELSE 0 END) AS nodo_2,
    SUM(CASE WHEN nodo = 'NODO 3' THEN 1 ELSE 0 END) AS nodo_3,
    SUM(CASE WHEN tipo_ingreso = 'DEP' THEN 1 ELSE 0 END) AS tipo_dep,
    SUM(CASE WHEN tipo_ingreso = 'NO_DEP' THEN 1 ELSE 0 END) AS tipo_nodep,
    SUM(CASE WHEN tipo_ingreso IS NULL OR tipo_ingreso = '' THEN 1 ELSE 0 END) AS tipo_blank,
    SUM(CASE WHEN flg_clean = 1 THEN 1 ELSE 0 END) AS clean_1,
    SUM(CASE WHEN flg_clean = 0 THEN 1 ELSE 0 END) AS clean_0,
    SUM(CASE WHEN flg_clean = 99 THEN 1 ELSE 0 END) AS clean_99
FROM disc_model_owner.ds_adm_pp_cdpp_cal
WHERE codmes >= '202311'
GROUP BY flg_ibk, sub_producto
ORDER BY flg_ibk, sub_producto
