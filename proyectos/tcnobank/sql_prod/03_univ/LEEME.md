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

## El reparo que no se resuelve con SQL

La calibracion se ajusto sobre **altas clean de TC no bancarizada**, ancladas a
una LRA de 6.98%. Los ~25M de esta tabla son el barrido mensual de todo el
universo scoreable, que no es esa poblacion: la mayoria nunca va a recibir una
tarjeta. Aplicarles ese ancla es una extrapolacion mas fuerte que la de IBK a
SS.FF. que ya esta documentada en doc/LIMITACIONES.md C3.

Esta tabla sirve para ver que haria la calibracion en el flujo de produccion.
Para validar la calibracion, la que manda sigue siendo `scr_adm_vcnbank_tc_cal`,
que es por alta y tiene mora observable.
