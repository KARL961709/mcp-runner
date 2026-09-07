# Spec dirty por producto (replicar flg_clean desplegado para 14M, a m-2)

Regla del usuario: **identificar dirty (= flg_clean=0 desplegado, por producto) -> coefs dirty; todo lo demas -> clean.**
codmes tabla = mes de alta = mes de score. Flags de origen a **codmes-2**. Ventanas cierran en codmes-2.
Fuente RCC: e_perm_aws.t_fact_report_rcc_rsk (>=201901) UNION d_perm_aws (201701-201812).

## Predicados RCC (cod_cuenta_rcc, verbatim)
- P1 castigo: SUBSTR(1,2)='81' AND SUBSTR(4,3) IN ('302','925') -> SUM(saldo)
- P2 refin: ((SUBSTR(1,2)='14' AND SUBSTR(4,1)='4') OR (SUBSTR(1,2)||'0'||SUBSTR(4,1) IN ('1405','1406') AND SUBSTR(7,2)='19')) AND clasif<>'8'
- P3 reest: igual P2 con SUBSTR(4,1)='3' y SUBSTR(7,2)='22'
- P4 judicial: SUBSTR(1,2)='14' AND SUBSTR(4,1)='6' AND clasif<>'8'
- P5 bancarizado: (81+923) OR (720506) OR (14 + SUBSTR(4,1) IN 1,3,4,5,6) OR (81+302/925). TC filtra tipo_credito IN('11','12','13')/('99'); PP sin filtro tipo_credito.
- P6 clasif: TC = cod_clasificacion_deudor IN ('2','3','4') [RCC]. PP = pct_clasif_def/dud/per > 0 [e_perm_aws.TBL_RCC_PER_ALLSF_MDL].
- P7 mora TC (dm_tc): condicion sobre ctas TC (lista SUBSTR(4,7)/(4,5)) tipo_credito 11/12 + 81/923.
- P8 saldo/mora PP (SLDPP/DM_PP): 96 codigos SUBSTR(1,10), tipo_credito 11/12, clasif<>'8'.
- P9 GH PP (SLDGH): SUBSTR(1,4) IN ('8414','8424','8434').

Ventanas (rel. a codmes): origen=codmes-2 ; u6m=[codmes-7,codmes-2] ; u12m=[codmes-13,codmes-2] ; u24m=[codmes-25,codmes-2].

## TC (binario, sin 99). flg_dirty_tc=1 si CUALQUIERA (a m-2):
clasif>CPP | castigo(origen O u24m) | refin(origen O u6m) | reest(origen) | judicial(origen O u24m) |
mora dm_tc>0(origen) | bancarizado: sld_bank u12m=0 -> dirty | edad NOT BETWEEN 21 AND 75 (RENIEC, a codmes) |
GH/convenio: e_perm_aws.t_consolidado_rsk (cons_periodo=codmes-2, por sbs_value) cons_salgarhip>0 OR cons_salprest*>0
[OMITIDOS inmateriales <0.5%: fraude (t_mst_fraude_rsk, 9), swaps (t_cob_facilidades..., 79), entidades (0)]

## PP (trivaluado: 1 clean / 99 scope-out / 0 dirty). Por regla: dirty=flg_clean=0; 99 y 1 -> clean.
GH (P9 sld_gh>0, m-2) y SALDO_PP (sld_pp fuera [3000,250000], a codmes+0) son **99 -> CLEAN** (no dirty).
flg_dirty_pp=1 si CUALQUIERA (a m-2), y NO cayo en 99:
clasif>CPP (P6-PP, TBL_RCC_PER_ALLSF_MDL) | atraso dm_pp>0(origen) | castigo(origen O u24m) | refin(origen O u6m) |
reest(origen O u6m) | judicial(origen O u24m) | bancarizado u12m=0 | edad NOT BETWEEN 21 AND 75 | cod_instit_financiera='00004'
[duplicado = dedup (rn=1), no es dirty real -> el universo ya es 1/persona]

## EC: all-clean. flg_clean=1 hardcodeado. Sin dirty. (config_ecvc.py confirmado)

## Caveats (del extractor)
- P7 TC: precedencia SQL del AND tipo_credito liga solo al ultimo OR -> transcribir verbatim.
- FRAUDE TC sin ventana temporal (presencia) -> leve look-ahead, asi esta desplegado (omitido igual).
- SALDO_PP se mide a codmes+0 (no m-2); es scope de admision -> en universo va a clean.
