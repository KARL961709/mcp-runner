-- chk_b_sent_dpa.sql | cuenta filas y meses de d_perm_aws.scr_admbankbpe_rsk_cal_202501_202608 (ver si se purgaron los datos). Agregado.
SELECT COUNT(*) AS n, COUNT(DISTINCT p_codmes) AS meses, CAST(MIN(p_codmes) AS VARCHAR) AS min_p, CAST(MAX(p_codmes) AS VARCHAR) AS max_p FROM d_perm_aws.scr_admbankbpe_rsk_cal_202501_202608
