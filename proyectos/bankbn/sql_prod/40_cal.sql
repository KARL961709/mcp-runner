-- 40. ENSAMBLADO -> ds_adm_bpe_bankbn_cal + flg_clean (D5 honesto; Top-4/D2 pendientes)
CREATE TABLE disc_model_owner.ds_adm_bpe_bankbn_cal AS
SELECT
    d.codmes, d.tip_doc, d.key_value,
    d.target_06m, d.target_09m, d.target_12m,
    d.probabilidad AS pd_raw,
    d.flg_ppjj, d.flg_impulsa, d.flg_impulsa_u12m, d.flag_bpe_parcial, d.flag_malo_12m,
    CASE
        WHEN d.flag_bpe_parcial = '19. PNSN'                    THEN 99
        WHEN d.probabilidad IS NULL                             THEN 98
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
