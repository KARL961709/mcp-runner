# sql_val_vc - target Vision Cliente vs target por entidad

Solo lectura. Ninguna consulta escribe ni crea tablas.

    .\Go.ps1 -SqlDir proyectos/tcnobank/sql_val_vc

## Que se esta midiendo

El original (`Recibidos/03.Scripts&Objetos/02.TARGET_kat.sql`) construye dos moras
lado a lado y usa la primera:

| | expresion | alcance |
|---|---|---|
| `dm_sf`  | `MAX(condicion)` sobre `14x` 4to digito 1,3,4,5,6 | **todas** las entidades, **todos** los creditos |
| `dm_ibk` | lo mismo `AND cod_instit_financiera='00002'`       | solo IBK |

`dsc_flg_malo_12m` se alimenta de `maxdm_rcc`, que sale de `dm_rcc_m1..m12`, que
salen de `dm_sf`. O sea el target del original **es Vision Cliente**. `dm_ibk` se
define y no se usa en ninguna otra linea de los tres scripts recibidos.

## Los dos targets se CRUZAN: ninguno domina al otro

Cada uno tiene dos patas y cada pata tiene alcance distinto:

| pata | ORIGINAL | NUESTRO | quien es mas ancho |
|---|---|---|---|
| mora  | `dm_sf`: RCC de **todo el sistema**, **todos** los creditos | `dm_tc` con `e.entidad = p.entidad`: solo la entidad de alta, solo tarjeta | **original** |
| duro  | `cc_castigos` desde `wrk_info_ibk` <- `t_rsk_fct_visioncliente`: **solo IBK** | `monto_cast`/`sld_jud`/`sld_ref`/`sld_ree` del RCC: **todo el sistema** | **nuestro** |

En teoria eso permite que un malo nuestro sea bueno del original, asi que
`solo_tc` podria no dar cero. **Medido: da cero.** En los 25 meses maduros,
sobre 190,686 emparejamientos, no hay una sola excepcion: `dm_sf` es tan ancha
que absorbe todo lo que marca nuestra pata dura. El cruce existe en la
definicion y no se materializa en el dato.

## MEDIDO 2026-08-18

- **Grano** el original tiene una fila por cliente: `n_filas = n_clientes =
  n_cli_ent` en las 41 cohortes.
- **Madurez** la ultima cohorte con `missing = 0` es **202503**; el RCC del
  original corta en 202603. De 202504 en adelante el target esta truncado y la
  brecha se da vuelta -llega a -2.95 pp en 202506- por artefacto, no por riesgo.
  **No comparar mas alla de 202503.**
- **Brecha** ventana 202303-202503: RD12 VC **12.7686%** vs RD12 TC **11.6506%**,
  o sea **+1.1181 pp**, **+9.6% relativo**. Mensual entre +0.63 y +1.49 pp.
- **Descomposicion** la entidad explica el **67%** de la brecha y el producto el
  **33%**. La pata de mora sola pasa de 39,889 a 43,905 malos al soltar la
  entidad: **+10.07%**.
- **Cobertura** el match cubre el **38.8%** de nuestra poblacion de calibracion.
  El original arranca de otra PO y su cascada excluye ramas enteras, asi que el
  NIVEL de cada curva no es la RD de ningun libro: **solo la diferencia es
  interpretable**.
- **Indeterminados** `13.Indeterm_60` entra al denominador contando como bueno.
  Son 3.13% de los evaluables, asi que empuja las dos RD hacia abajo por igual.

## Calendario

En el original `cod_mes = p_codmes - 2` y la ventana del target es
`[cod_mes+1, cod_mes+12]`. Es el mismo ancla que nuestro `codmes_mrm`, asi que
**`cod_mes` empareja contra `codmes`** sin desplazar nada.

## Que devuelve cada una

- **v01** grano y distribucion del target original por cohorte. `n_filas` vs
  `n_clientes` dice si esta deduplicado a un cliente por fila; `n_insuf` y
  `n_uncash` dicen desde que cohorte hay 12m maduros.
- **v02** la brecha mensual. `sin_match` es la cobertura; la matriz 2x2
  (`ambos`, `solo_vc`, `solo_tc`, `ninguno`) es la desviacion R11.
- **v03** parte la brecha en sus dos ejes: recalcula nuestro target quitando solo
  el filtro de entidad. `solo_otra_ent` es el eje ENTIDAD puro; lo que quede
  contra v02 es el eje PRODUCTO.

v01 barre todas las particiones de la tabla original. Si el runner corta por
timeout la consulta igual puede haber terminado: revisar antes de relanzar.
