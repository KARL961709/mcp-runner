# Simulador estres FEN - Campana PP 202609

Objetivo: simulador sobre la campana PP (producto=PP, sub_producto=PP, num_carga='2.1 Rec', p_codmes=202609)
mostrando la progresion de PD por celda de corte, con datos REALES (nada ilustrativo):

    PD raw  ->  PD TTC  ->  PD PIT (calibrada)  ->  PD PIT FEN (con overlay)

y la migracion de grados (G1..G6, GR) bajo los puntos de corte 2609.

Recuperacion: SOLO INFLACION (decision del usuario 2026-09-22). El rec_d por departamento sale del
entregable `elnino_ibk/05_entregables/recuperacion_fen_calculo.xlsx`, hoja RESUMEN col INFLACION. No se
usa IBK+ ni el MIX en este simulador.

## Fuentes (nombres de columna VERIFICADOS)
- Campana: `d_perm_aws.t_edc_ar_camp_vars_sep2qrec_temp` (llave subject_id, 66 chars, prefijo '1-')
- Scores 2609: `d_perm_aws.scr_vcadmbnk_final_rsk_cal_2609` (31 cols, una fila por key_value)
    - `pd_raw`                        = PD raw
    - `prob_modelo_ttc_cal_ppfacil`   = PD TTC (PP Facil)
    - `prob_modelo_cal_ppfacil`       = PD PIT (PP Facil)
    - `puntuacion_modelo_cal_ppfacil` = score PIT -> grado (cortes 2609)
- R (score directo FEN por persona): `disc_model_owner.mca_bd_reniec_xy_r_reest`
    - `key_value`, `r_label_reest` (R0..R5), `r_nivel_reest` (gate Pacifico si >=1), `ubigeo_inei_nodo`, `exp25`, `exp50`
- s (score INDIRECTO actividad-agua): `disc_model_owner.fen_s_indirecto` (`ubigeo`, `s_total`, `nivel` S0..S4)
    - join por r.ubigeo_inei_nodo = s.ubigeo -> termino wA*s

## Puente confirmado (e08)
`substr(subject_id, 3) = key_value`  (subject_id = '1-' + key_value de 64 chars).
Cobertura: 2,253,762 de 2,512,001 filas de campana matchean R = 89.7% (el resto sin geolocalizacion RENIEC).
La campana trae ~10k subject_id duplicados (2,512,001 filas / 2,501,992 distintos) -> se deduplica por llave.

## Cortes 2609 (score PIT -> grado)
G1 >=985 (PD ref 1.05%) | G2 >=955 (3.08%) | G3 >=947 (4.95%) | G4 >=912 (7.00%) | G5 >=892 (9.80%) | G6 >=864 (12.47%) | GR <864

## Overlay FEN (PIT -> PIT FEN), motor identico al simulador PEA validado
    shift = lam * gamma * pac * max(wF*d + wA*s, 0) * (1 - wrec * rec_d[depto])
    d = R/5 ; pac = (r_nivel_reest >= 1) ; lam = sqrt(rho/(1-rho)) ; rho = 0.0332 (calibracion PP VC, NO 0.15)
    rec_d[depto] = factor de recuperacion por INFLACION (ventana oficial Yaku, vara mediana de ciudades)
CAMBIO vs PEA: recA pasa de uniforme (1 - wrec) a por-departamento (1 - wrec * rec_d[depto]).

## Estado
- sql_val/ e01..e08 = exploracion (esquemas, llaves, cruce). e08 confirmo el puente.
- sql_val/ e09_extract_celdas.sql = EXTRACCION agregada final. Grano: dep_inei x R_reest x grado_PIT.
  Devuelve n, pd_raw, pd_ttc, pd_pit, score_avg, s_avg, exp25/50, min/max pd_pit. Solo agregados salen.
  Correr:  .\Go.ps1 -SqlDir proyectos/fen_pp_sim/sql_val -Only e09_extract_celdas
- Siguiente: pegar el _resultados.txt de e09 -> se inyecta al artifact -> simulador con datos reales 2609.
