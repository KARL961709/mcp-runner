-- v_s1_cobertura.sql | desde/hasta cuando existe score y cuanto viene sin probabilidad
SELECT min(p_codmes)                       AS pcodmes_min,
       max(p_codmes)                       AS pcodmes_max,
       count(DISTINCT p_codmes)            AS meses,
       count(1)                            AS filas,
       count(probabilidad)                 AS con_prob,
       count(1) - count(probabilidad)      AS sin_prob
FROM e_perm_aws.scr_admbankbpe_rsk
