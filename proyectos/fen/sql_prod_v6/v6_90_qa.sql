SELECT count(*) AS n_dist, count(DISTINCT cod_ubigeo) AS n_ubigeo,
       sum(CASE WHEN r_nivel >= 4 THEN 1 ELSE 0 END) AS n_r45,
       sum(CASE WHEN r_nivel = 0 THEN 1 ELSE 0 END)  AS n_r0,
       sum(CASE WHEN tipo_actividad = 'PESQUERO' THEN 1 ELSE 0 END) AS n_pesquero,
       count(altitud) AS n_con_altitud,
       max(length(distrito)) AS max_len_distrito
FROM disc_model_owner.fen_score_v6
