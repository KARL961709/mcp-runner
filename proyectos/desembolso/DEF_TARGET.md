# Definicion exacta del TARGET de desembolsos

Especificacion portable para replicar el target desde el RCD (e_perm_aws.t_ifrs_rcddeta_rsk)
y mapear campos equivalentes. Refleja lo que corre hoy en
proyectos/desembolso/sql_prod/2_desemb_target.sql

## 1. Poblacion, fuente y grano
- Poblacion (universo): d_perm_aws.user_desembolso, TODAS las filas
- Fuente del malo (hoy): e_perm_aws.t_fact_report_rcc_rsk (RCC consolidada)
- Filtro de entidad: cod_instit_financiera = '00002'   (SOLO Interbank)
- Ventana de lectura RCC: codmes y p_codmes entre 202302 y 202612
- Grano del target: (cod_mes, cod_tip_doc, key_value)
- cod_mes = mes del desembolso (alta)

## 2. Columnas RCC usadas y candidato equivalente en el RCD
| proposito              | columna en RCC (hoy)      | candidato en RCD (t_ifrs_rcddeta_rsk)       |
|------------------------|---------------------------|---------------------------------------------|
| mes de observacion     | codmes / p_codmes         | codmes / p_codmes                           |
| llave cliente          | tip_doc + key_value       | cod_cuc  (-> key_value via t_mst_ctaibk_rsk)|
| entidad                | cod_instit_financiera     | (RCD es interno IBK, no aplica filtro)      |
| tipo de credito        | tipo_credito (1..10)      | ti_cred                                     |
| cuenta contable/estado | cod_cuenta_rcc (string)   | nu_cnta_cntb / co_rubr / co_scta            |
| dias de atraso         | condicion                 | nu_dias_vcdo / dias_vcdo_o                  |
| saldo (no usado)       | -                         | im_sald_eqvl                                |

## 3. Malo por mes RCC (por cliente), SOLO en cuentas con tipo_credito entre 1 y 10
Leyendo el string cod_cuenta_rcc por posiciones (substr(campo, inicio, largo)):

dm (dias de mora) = MAX(condicion) SOLO en cuentas que califican:
      ( substr(cod_cuenta_rcc,1,2) = '14'
        AND substr(cod_cuenta_rcc,7,2) NOT IN ('01','04')
        AND substr(cod_cuenta_rcc,4,1) IN ('1','3','4','5','6') )
   OR ( substr(cod_cuenta_rcc,1,2) = '81'
        AND substr(cod_cuenta_rcc,4,3) IN ('302','925') )

ree (reestructurado) = 1 si  substr(1,2)='14' AND substr(4,1)='3'
ref (refinanciado)   = 1 si  substr(1,2)='14' AND substr(4,1)='4'
jud (judicial)       = 1 si  substr(1,2)='14' AND substr(4,1)='6'
cst (castigo)        = 1 si  substr(1,2)='81' AND substr(4,3) IN ('302','925')

bad(mes) = 1  si  (dm > 90) OR ree=1 OR ref=1 OR jud=1 OR cst=1 ;  si no, 0

Notas:
- dm, ree, ref, jud, cst se agregan por MAX dentro del mes: si CUALQUIER cuenta del
  cliente lo tiene, la senal del mes es 1.
- Cliente sin fila RCC IBK en el mes => bad = 0 (no NULL).

## 4. Horizonte (escalera 1..12)
Para un desembolso en cod_mes:
  w_h = cod_mes + h meses     (h = 1..12, aritmetica de fecha sobre YYYYMM)
  target_hm = MAX( bad(codmes_rcc) )  sobre meses RCC con  w_1 <= codmes_rcc <= w_h
Acumulado y monotono: si target_9m=1 => target_10m = target_11m = target_12m = 1
Interpretacion: malo a h meses = tuvo alguna senal en IBK en algun mes de
[cod_mes+1, cod_mes+h].

## 5. Madurez (censura, NO se pone 0)
  fr = MAX(codmes) disponible en la RCC   (frontera de datos, hoy 202607)
  target_hm = NULL  si  (cod_mes + h) > fr     (horizonte no cerrado)
  meses_madurez = min(12, meses de cod_mes a fr), acotado a [0,12]
  rcc_frontera  = fr

## 6. Para replicar desde el RCD (lo que falta medir)
- mora>90 : directo con try_cast(nu_dias_vcdo AS int) > 90  (sin parseo de string).
- refin/reest/judicial/castigo : mapear desde nu_cnta_cntb / co_rubr / co_scta.
  OJO: los CODIGOS del RCD NO son los mismos que cod_cuenta_rcc. Hay que medir sus
  valores distintos (ver sql_diag/17_rcd_clasificadores.sql) y asignar cada codigo a
  un estado antes de escribir la logica.
- entidad : el RCD es interno IBK, equivale al filtro cod_instit_financiera='00002'.
- llave  : cod_cuc del RCD -> key_value via e_perm_aws.t_mst_ctaibk_rsk
  (cobertura 100%, cod_cuc->key_value 1:1).
- grano  : el RCD esta a nivel cuenta contable; agregar a (key_value, mes) por MAX,
  igual que en la RCC.
- recuperaciones : definir el alcance (cobranza vencido+judicial / castigados
  recuperados / rubro propio) antes de incluirlo en el malo.
