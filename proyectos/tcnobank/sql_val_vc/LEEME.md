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

Nuestro `50_targets.sql` se desvia en dos ejes a la vez:

- **entidad**: `e.entidad = p.entidad` en la pata de mora
- **producto**: `dm_tc` es solo tarjeta; `dm_sf` es todo credito

Los dos ejes solo pueden **quitar** malos, asi que nuestra RD es cota inferior de
la del original.

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
