# Simulador estres FEN - Campana PP 202609

Objetivo: simulador sobre la campana PP (producto=PP, sub_producto=PP, num_carga='2.1 Rec', p_codmes=202609)
mostrando la progresion de PD por celda de corte:

    PD raw  ->  PD TTC  ->  PD PIT (calibrada)  ->  PD PIT FEN (con overlay)

y la migracion de grados (G1..G6, GR) bajo los puntos de corte 2609.

## Fuentes
- Campana: `d_perm_aws.t_edc_ar_camp_vars_sep2qrec_temp` (llave subject_id, trae ubigeo_dep, tipo, exposicion)
- Scores PIT: `d_perm_aws.scr_vcadmbnk_final_rsk_cal_2609`
    - prob_modelo_cal_ppfacil = PD PIT (sub_producto PP -> PP Facil)
    - puntuacion_modelo_cal_ppfacil = score PIT (para el grado)
- PD raw: `disc_riesgos.scr_vcbankv3_repro_opt_` (prob_model, llave key_value + cod_tip_doc)  [por confirmar]
- R (score directo FEN por persona): `disc_model_owner.mca_bd_reniec_xy_r_reest` (r_label, r_label_reest/r_nivel_reest, ubigeo_inei_nodo, exp25/50)
- s (score INDIRECTO, actividad-agua): `disc_model_owner.fen_s_indirecto` (ubigeo distrito, s_total, nivel S0..S4) -> join por r.ubigeo_inei_nodo = s.ubigeo -> termino wA*s

## Patron de cruce (del pipeline fen_overlay/sql_prod/s03)
El pipeline vigente une scores x R POR key_value: `u.key_value = r.key_value`.
La campana usa subject_id -> HAY QUE CONFIRMAR si subject_id = key_value (e06). Si si, cruce 3-vias por esa llave.
Reusar s03: grado por cortes, r_reest, pac=CASE r_nivel_reest>=1, depto=substr(ubigeo_inei_nodo,1,2), exp25/50.
CAMBIO clave del simulador nuevo: reemplazar `fen_ibk_plus` (resiliencia IBK+) por el rec_d de la metodologia INFLACION.

## Puntos de corte 2609 (score PIT -> grado)
G1 >=985 (PD 1.05%) | G2 >=955 (3.08%) | G3 >=947 (4.95%) | G4 >=912 (7.00%) | G5 >=892 (9.80%) | G6 >=864 (12.47%) | GR <864 rechazo

## Overlay FEN (PIT -> PIT FEN)
shift = lam * gamma * costa * (wF*R/5 + wA*s) * (1 - wrec * rec_d)
rec_d = factor de recuperacion por departamento (metodologia inflacion, ventana oficial Yaku, vara mediana de ciudades)

## Estado
sql_val/ = exploracion (e01..e05): esquemas, llaves y cruce. Correr: .\Go.ps1 -SqlDir proyectos/fen_pp_sim/sql_val
Siguiente: extraccion agregada por depto x R x grado con las PD, y armado del simulador.
