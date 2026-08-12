-- 14_scr_disponibilidad.sql | ventana y volumen del score nuevo vcnbank, que define desde cuando se puede calibrar contra el
SELECT p_codmes,
       count(*)                                                     AS n,
       count(DISTINCT key_value)                                    AS clientes,
       min(TRY_CAST(puntuacion AS INTEGER))                         AS p_min,
       round(avg(TRY_CAST(puntuacion AS DOUBLE)), 1)                AS p_media,
       max(TRY_CAST(puntuacion AS INTEGER))                         AS p_max,
       sum(CASE WHEN puntuacion IS NULL THEN 1 ELSE 0 END)          AS nulos
FROM e_perm_aws.scr_vcnbank_rsk
GROUP BY p_codmes
ORDER BY p_codmes
