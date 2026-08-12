-- ============================================================================
-- 96. LINAJE - NINGUN FILTRO DISPARA ANTES DE QUE SU FUENTE EXISTA
-- ============================================================================
SELECT 'G6' AS gate, chk, n_viol, n_magnitud,
       CASE WHEN n_viol = 0 THEN 'PASS' ELSE 'FAIL' END AS veredicto
FROM (
    SELECT 'fraude que dispara antes de 202106' AS chk,
           sum(CASE WHEN ctrl_sin_fraude = 1 AND f_fraude = 1 THEN 1 ELSE 0 END) AS n_viol,
           sum(ctrl_sin_fraude) AS n_magnitud FROM disc_model_owner.ds_adm_vcnbank_tc_cal
    UNION ALL
    SELECT 'swap u12m que dispara antes de 202201',
           sum(CASE WHEN ctrl_sin_swap = 1 AND f_swap_u12m = 1 THEN 1 ELSE 0 END),
           sum(ctrl_sin_swap) FROM disc_model_owner.ds_adm_vcnbank_tc_cal
    UNION ALL
    SELECT 'inca con dato antes de 202305',
           sum(CASE WHEN codmes_mrm < '202305' AND ctrl_inca_sin_dato = 0 THEN 1 ELSE 0 END),
           sum(CASE WHEN codmes_mrm < '202305' THEN 1 ELSE 0 END) FROM disc_model_owner.ds_adm_vcnbank_tc_cal
    UNION ALL
    SELECT 'altas fuera de la ventana 201902 a 202605',
           sum(CASE WHEN codmes_mrm < '201902' OR codmes_mrm > '202605' THEN 1 ELSE 0 END),
           count(*) FROM disc_model_owner.ds_adm_vcnbank_tc_cal
) y
