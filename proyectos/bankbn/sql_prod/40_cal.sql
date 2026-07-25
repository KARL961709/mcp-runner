-- ============================================================================
-- 40. ENSAMBLADO ds_adm_bpe_bankbn_cal + flg_clean  (encoda caso_filtros + D5)
-- flg_clean: 99 estructural(top4/PNSN) | 98 sin score | 1 clean(honesto, CASO1 liberados) | 0 dirty
-- Placeholder <ENT_TOP4> = lista de cod_instit_financiera Top-4 (BCP/BBVA/Scotia/IBK).
-- ============================================================================
DROP TABLE IF EXISTS disc_model_owner.ds_adm_bpe_bankbn_cal;

CREATE TABLE disc_model_owner.ds_adm_bpe_bankbn_cal AS
SELECT
    d.codmes, d.tip_doc, d.key_value, d.cod_instit_financiera,
    d.target_06m, d.target_09m, d.target_12m,
    d.probabilidad AS pd_raw,
    d.flg_ppjj, d.flg_impulsa, d.flg_impulsa_u12m, d.flag_bpe_parcial, d.flag_malo_12m,
    -- filtro_i (1 = el filtro excluye al registro; 0 = lo pasa)
    CASE WHEN d.flag_malo_12m = 'CASTIGADO_ORIGEN'      THEN 1 ELSE 0 END AS filtro_castigado_org,
    CASE WHEN d.flag_malo_12m = 'JUDICIAL_ORIGEN'       THEN 1 ELSE 0 END AS filtro_judicial_org,
    CASE WHEN d.flag_malo_12m = 'REESTRUCTURADO_ORIGEN' THEN 1 ELSE 0 END AS filtro_reest_org,
    CASE WHEN d.flag_malo_12m = 'REFINANCIADO_ORIGEN'   THEN 1 ELSE 0 END AS filtro_refin_org,
    CASE WHEN d.flag_malo_12m = 'CLASIF_NO_NORMAL'      THEN 1 ELSE 0 END AS filtro_clasif,
    CASE WHEN d.flag_malo_12m = 'CON_DIASATRASO_ORIGEN' THEN 1 ELSE 0 END AS filtro_diasatraso_org,
    CASE WHEN d.flag_bpe_parcial IN ('01. Titular con Saldo Comercial No Vigente RCC (Ultimo mes)',
                                     '02. Titular con Saldo Comercial No Vigente RCC (Ultimos 12 meses)',
                                     '03. Titular con Calificacion SBS diferente a 100% Normal',
                                     '09. RRLL con Saldo RCC en Castigo (Ultimos 12 meses)') THEN 1 ELSE 0 END AS filtro_bpe_honesto,
    CASE WHEN d.flag_bpe_parcial IN ('17. Titular >= 75 o < 25 anos','18. RRLL >= 75 o < 25 anos') THEN 1 ELSE 0 END AS filtro_edad,
    -- CASO1 (look-ahead): se marcan pero NO excluyen del clean (D5 los libera)
    CASE WHEN d.flag_bpe_parcial IN ('20. Estado Diferente A','22. Giro Restringido','23. Ubigeo Restringido') THEN 1 ELSE 0 END AS filtro_sunat_LA,
    CASE WHEN d.flag_malo_12m = 'ESPECIALES'  THEN 1 ELSE 0 END AS filtro_especiales_LA,
    d.flg_impulsa_u12m                                       AS filtro_impulsa_u12m_LA,
    -- flg_clean (D5: honesto = libera CASO1)
    CASE
        WHEN d.cod_instit_financiera NOT IN (<ENT_TOP4>)       THEN 99
        WHEN d.flag_bpe_parcial = '19. PNSN'                   THEN 99
        WHEN d.probabilidad IS NULL                            THEN 98
        WHEN d.flag_malo_12m IN ('CASTIGADO_ORIGEN','JUDICIAL_ORIGEN','REESTRUCTURADO_ORIGEN',
                                 'REFINANCIADO_ORIGEN','CLASIF_NO_NORMAL','CON_DIASATRASO_ORIGEN') THEN 0
        WHEN d.flag_bpe_parcial IN ('01. Titular con Saldo Comercial No Vigente RCC (Ultimo mes)',
                                    '02. Titular con Saldo Comercial No Vigente RCC (Ultimos 12 meses)',
                                    '03. Titular con Calificacion SBS diferente a 100% Normal',
                                    '09. RRLL con Saldo RCC en Castigo (Ultimos 12 meses)',
                                    '17. Titular >= 75 o < 25 anos','18. RRLL >= 75 o < 25 anos') THEN 0
        ELSE 1
    END AS flg_clean
FROM disc_model_owner.ds_adm_bpe_bankbn_drivers d
;
