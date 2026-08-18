# 03_univ - la calibracion sobre TODO el universo scoreado

Tabla `disc_model_owner.scr_univ_vcnbank_tc_cal`. Una fila por cada fila de
`scr_vcnbank_rsk`, con `prob_modelo_cal` y `puntuacion_cal` = **nuestra**
calibracion. Las que la fuente traia con esos nombres viajan como `*_vigente`.

## PRIMERO EL PILOTO, y cronometrado

    .\Run-Athena.ps1 -SqlDir proyectos/tcnobank/sql_prod/00_reset -Only r024_drop_scr_univ.sql
    .\Run-Athena.ps1 -SqlDir proyectos/tcnobank/sql_prod/03_univ -Only 80_scr_univ_t01_piloto.sql

Un solo mes: 202605, ~24.9M filas. **Anotar los segundos que reporta el
`_resumen.txt`** y pegarlos de vuelta. Con eso se sizea el resto: son 42 meses y
~1,090 millones de filas en total.

Si da `TIMEOUT`, el limite es del runner (900s por defecto) y no de Athena, y la
tabla puede haber quedado creada: correr la QA antes de relanzar. Si hace falta,
subir el timeout con `-TimeoutSec`.

## Por que un piloto y no los 42 de una

`30_drivers` deja anotado que la poblacion entra por INNER JOIN ANTES de cada
ventana porque si no el `row_number` ordena 1,250 millones de filas de `t_inca_sa`
y Athena agota recursos. Con las altas esa poblacion son ~200K por mes; aca son
~25M, o sea 123 veces mas, y casi no restringe. El paso `arq` es el que puede no
correr, y hay que saberlo con un mes gastado y no con 42.

El sizing tampoco se extrapola lineal: ya paso en el RCC, donde 6 a 24 meses se
estimo 4x y el real fue 1.9x porque el lookback es cola fija.

## Que mirar cuando termine

- filas escritas ~= 24,878,915 (lo que 02_cobertura conto para 202605)
- `nodo_calc` sin nulos
- `ctrl_nodo_observado = 0` en la gran mayoria: las tres fuentes del nodo son
  internas de Interbank y este universo es mucho mas ancho que su base de
  clientes. Un N3 masivo aca es lo esperado, no un defecto
- `prob_modelo_cal` sin nulos: las 42 particiones traen `prob_model` en el 100%

## Que es esta tabla

Es la **poblacion objetivo sobre la que se lanza el modelo**, no altas: los
desembolsos todavia no ocurrieron. Por eso no trae mora ni identificacion de
alta, y no tiene por que traerlas — un modelo de admision existe para
pronunciarse antes.

La fuente ya trae `prob_modelo_cal`, `puntuacion_cal` y `grupo_calibracion` sobre
sus ~25M filas: la calibracion vigente ya vive en esta superficie. Este build la
reemplaza, y como las dos viajan lado a lado sobre las mismas filas se pueden
comparar de frente:

| nuestra | vigente |
|---|---|
| `prob_modelo_cal` | `pd_cal_vigente` |
| `puntuacion_cal` | `puntuacion_cal_vigente` |
| `grupo_cal` | `grupo_cal_vigente` |

`grupo_cal` viene con los puntos de corte de la opcion B ya aplicados
-`972 | 964 | 938 | 899 | 768`-, que es la columna que decide la oferta.

## La otra tabla

`scr_adm_vcnbank_tc_cal` es por alta y llega hasta 202606, lo que el RCC permite.
Sirve para lo que aca no se puede hacer: contrastar la PD contra la mora
observada. Las dos hacen falta y ninguna reemplaza a la otra.
