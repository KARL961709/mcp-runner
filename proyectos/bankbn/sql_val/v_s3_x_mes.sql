-- v_s3_x_mes.sql | volumen de score por mes: donde arranca de verdad y si hay huecos
SELECT p_codmes,
       count(1)                    AS filas,
       count(probabilidad)         AS con_prob,
       count(DISTINCT key_value)   AS clientes
FROM e_perm_aws.scr_admbankbpe_rsk
GROUP BY p_codmes
ORDER BY p_codmes
