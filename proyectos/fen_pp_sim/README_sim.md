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
- R (score directo FEN por persona): `mca_bd_reniec_xy_r_reest` (R_LABEL_REEST, ubigeo)

## Puntos de corte 2609 (score PIT -> grado)
G1 >=985 (PD 1.05%) | G2 >=955 (3.08%) | G3 >=947 (4.95%) | G4 >=912 (7.00%) | G5 >=892 (9.80%) | G6 >=864 (12.47%) | GR <864 rechazo

## Overlay FEN (PIT -> PIT FEN)
shift = lam * gamma * costa * (wF*R/5 + wA*s) * (1 - wrec * rec_d)
rec_d = factor de recuperacion por departamento (metodologia inflacion, ventana oficial Yaku, vara mediana de ciudades)

## Estado
sql_val/ = exploracion (e01..e05): esquemas, llaves y cruce. Correr: .\Go.ps1 -SqlDir proyectos/fen_pp_sim/sql_val
Siguiente: extraccion agregada por depto x R x grado con las PD, y armado del simulador.
