# Scoring UNIVERSO VC (14M/mes) — 202606-202608, 4 modelos

Scorea el universo `d_perm_aws.scr_vcadmbnk_final_hist_rsk` (~14M/mes) con los 4 modelos
(PP Fácil, PP CD, EC, TC), produciendo por persona `prob_modelo_cal_{ppfacil,ppcd,ec,tcbnk}`
+ `puntuacion_modelo_cal_{...}` = `round(1000*(1-pd))`.

## Regla clean/dirty (SIN look-ahead)
En producción **solo se conoce el DIRTY** (deterioro OBSERVABLE en el RCC al originar).
El outcome (BUENO/MALO/INSUF/INDET…) NO se conoce → **clean por default**.
```
flg_dirty_<prod> = 1  si deterioro-en-origen observable del producto ; else 0 (clean)
```
DIRTY = castigo · judicial · refinanciado · reestructurado · atraso/malos en origen · bancarizado ·
clasif > CPP · **fraude**. TC y PP casi iguales; **EC no tiene dirty → siempre clean**.

## BLOQUE B — campos a AGREGAR a scr_vcadmbnk (insumo, los agregan ustedes)
Deben venir con las MISMAS categorías/strings de `02_Logica_nodos.sql` (si no, el binning no matchea).

| campo | tipo | fuente |
|---|---|---|
| `tipo_ingreso` | varchar (DEP/NO_DEP) | renta / sit_lab |
| `flg_dirty_tc` | int (1/0) | deterioro-origen observable (regla TC) |
| `flg_dirty_pp` | int (1/0) | deterioro-origen observable (regla PP) |
| `flg_inmueble` | int (0/1) | SUNARP |
| `nro_inmuebles` | varchar ('00.=0'/'01.=1'/'02.>1') | SUNARP |
| `nivel_profesional` | varchar ('01.BACH'/'02.TITU'/'03.TITU_2NDO'/'04.MAGI'/'05.DOCT'/null) | maestra profesiones |
| `cant_trx_out_tot_u3m` | varchar ('00.0_U3M'/'01.1_U3M'/'02.2_U3M'/'03.3_U3M') | Yape/Plin |
| `cant_trx_in_out_tot_u3m` | varchar (idem U3M) | Yape/Plin |
| `cant_trx_in_out_tot_u6m` | varchar ('00.0_U6M'…'06.6_U6M') | Yape/Plin |
| `cant_trx_out_yap_u6m` | varchar ('00.0_U6M'…'06.6_U6M') | Yape/Plin |
| `flg_cs_v2` | int (0/1) | cuenta sueldo |
| `cant_uso_tc_tot_5porc_u6m` | varchar ('00.NO_TC'/'01.=0'/'01.=1'/'02.=2'…'06.=6') | uso TC (RCC) |
| `flg_top25` | int (0/1) | RCC |

Llaves que ya trae: `codmes`, `cod_tip_doc`, `key_value`, `probabilidad` (= pd_raw).
EC no requiere `flg_dirty_ec` (siempre clean).

## Pipeline (sql_prod, CTAS de a uno con -Only)
```
u00_drop / u01_nodos   scr_vcadmbnk enriquecida -> bins + nodo_tc/_ec/_ppfacil/_ppcd  -> univ_vc_nodos
u02_drop / u02_scored  univ_vc_nodos -> 4 calibraciones (coefs inline) -> univ_vc_scored
                        (prob_modelo_cal_* + puntuacion_modelo_cal_* + puntuacion 0-1000)
```
Árbol de nodos EXTRAÍDO de `EC VC/Reproceso/02_Logica_nodos.sql` (no transcrito). Coefs de los 3
productos (`<prod> VC/calibracion/outputs/`). Piloto sugerido: correr **202608** primero.
