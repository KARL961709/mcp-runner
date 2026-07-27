-- v_s6_pcodmes.sql | en el score codmes y p_codmes son el mismo mes? el join del MAD usa p_codmes
SELECT CASE WHEN codmes = p_codmes THEN 'IGUAL' ELSE 'DISTINTO' END AS relacion,
       count(1)       AS filas,
       min(p_codmes)  AS p_min,
       max(p_codmes)  AS p_max,
       min(codmes)    AS c_min,
       max(codmes)    AS c_max
FROM e_perm_aws.scr_admbankbpe_rsk
GROUP BY 1
