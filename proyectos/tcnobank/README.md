# tcnobank — calibracion TC No Bancarizado

## Que se esta decidiendo

Hay **dos modelos** con el mismo nombre comercial y **poblaciones distintas**:

| | vigente `admtcnobk1` | nuevo `vcnbank` |
|---|---|---|
| score | scorecard WoE, 24 vars, `scr_admtcnobk1_rsk` | CatBoost, 26 vars, `scr_vcnbank_rsk` |
| producto | TC unicamente | TC + prestamo personal |
| entrada | altas de TC (`tng_altas_ssff_rsk` + `tng_altas_ibk_rsk`) | RCC consumo 11/12 con alta al sistema |
| grano | cliente x entidad + prelacion | cliente (mayor saldo) |
| bueno | max dm 12m <= 8 | max dm 12m <= 29 |
| edad | 21-75 | 21-50 |
| flags calib | `flg_per` / `flg_est` ya definidos | no existen |

La ronda R1 mide cual de los dos moldes sostiene la calibracion, y con cuanta
poblacion queda cada filtro.

## Ronda R1 (read-only, agregados)

Correr:

    .\Go.ps1 -SqlDir proyectos\tcnobank\sql_val

| # | que responde |
|---|---|
| 01 | existen las tablas de ambos modelos y en que esquema |
| 02 | esquema de la tabla de flags vigente |
| 03 | esquema de altas, scores y los dos `t_inca` |
| 04 | cuanta historia hay para calibrar |
| 05 | **cobertura de cada filtro** de la PO vigente |
| 06 | cuanto mueve el horizonte 6 / 9 / 12m |
| 07 | serie mensual de la base de calibracion y tasa de malos |
| 08 | **si las altas son solo IBK o todo el sistema** |
| 09 | reparto por entidad emisora y peso del filtro de 5 entidades |
| 10 | entidades que sobreviven a `flg_est` / `flg_per` |
| 11 | **poblacion que cambia de clase** al mover la banda 9-60 -> 30-60 |
| 12 | tasa de malos por tramo de score |
| 13 | cobertura de filtros de la PO nueva, partida TC vs PP |
| 14 | desde cuando existe el score nuevo |

Las 14 son independientes: si una falla el lote sigue. 02 y 03 son sondas de
esquema a proposito, para que un nombre equivocado se diagnostique en el mismo
viaje en vez de costar otro.

## Riesgos conocidos antes de correr

- `scr_vcnbank_rsk` puede usar `fecinformacion` en vez de `p_codmes` (asi lo hace
  el score vigente). Si 14 falla, 03 trae el nombre correcto.
- `t_inca_sa` (pedido en `tablas.txt` con rezago -2) **no es** `t_inca_vnb`, que es
  la que usa el desarrollo. 01 y 03 confirman si ambas existen.
- La tabla de flags identifica la entidad por **nombre**, no por codigo.
