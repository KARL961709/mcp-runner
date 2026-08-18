# sql_prod_vc - target Vision Cliente pegado a la tabla de calibracion

Construye `disc_model_owner.ds_adm_vcnbank_tc_cal_vc` = la tabla de calibracion
actual **entera**, mas 15 columnas nuevas. **No toca `ds_adm_vcnbank_tc_cal`.**

## Que cambia respecto del target actual

`52_target_vc.sql` esta DERIVADO de `50_targets.sql` por sustitucion, no
reescrito. El diff completo contra el original es:

1. el nombre de la tabla de salida
2. `e.dm_tc` -> `e.dm_sf`, doce veces, una por horizonte
3. la fuente de la mora: `05_rcc_agg` -> `51_dmsf`, y se cae la linea
   `AND e.entidad = p.entidad`

**Nada mas.** La pata dura -castigo, judicial, refinanciado, reestructurado,
todo el sistema-, la regla de madurez y el `GROUP BY` quedan byte a byte
identicos. Por eso `target_vc_12m` contra `target_12m` aisla exactamente el
efecto de la mora y de nada mas.

`dm_sf` se copia del recibido `02.TARGET_kat.sql:224`:

    substr(cod_cuenta_rcc,1,2) IN ('14')
    AND substr(cod_cuenta_rcc,4,1) IN ('1','3','4','5','6')
    AND cod_clasificacion_deudor <> '8'   ->   max(condicion)

Sin filtro de entidad y sin filtro de `tipo_credito`. Esos dos son justamente
los que lo hacen Vision Cliente: el primero abre el eje ENTIDAD y el segundo el
eje PRODUCTO. Medidos contra el original valen 67% y 33% de la brecha.

## Orden de ejecucion

    00_reset/            solo si hay que rehacer
    51_dmsf_t01 .. t08   la mora del sistema, por tramos anuales
    52_target_vc         el target
    53_cal_vc            el ensamble

**Corre `51_dmsf_t05` primero y cronometralo.** Es 2023, doce particiones, el
tramo tipico. Los ocho tramos juntos barren `e_perm_aws.t_fact_report_rcc_rsk`
de 201903 a 202606, que son 88 particiones de la tabla mas grande del RCC. El
`JOIN` contra las llaves distintas de `11_po_key` es lo que lo hace viable.
Si el piloto sale caro, ese join es lo primero a mirar.

Construir **de a uno**: el `catch` del runner no corta, asi que un fallo genera
errores en cascada y la causa raiz es siempre el primero.

### Si solo necesitas la ventana de calibracion

`51_dmsf_t05` a `t08` cubren 202301-202606, o sea cohortes desde **202212**.
Con eso alcanza para calibrar y cuesta la mitad. Las cohortes anteriores quedan
con `target_vc_*` en NULL, que es lo correcto -no hay dato-, pero **ojo si
alguien usa `flg_hist` para la serie de RD del modelo macro**: esa serie
arranca antes y se quedaria corta.

## Verificacion

    .\Go.ps1 -SqlDir proyectos/tcnobank/sql_val_vc_build

- **q01** el ensamble no abrio filas: `n_cal = n_cal_vc`, `n_dup = 0`.
- **q02** la matriz 2x2. **`solo_tc` tiene que dar 0.** La pata dura es la misma
  en los dos targets y `dm_sf` contiene a `dm_tc` por construccion, asi que un
  `solo_tc > 0` significa build roto, no hallazgo.
- **q03** monotonia por horizonte y madurez creciente hacia el horizonte corto.
- **q04** cobertura de `51_dmsf` **contando filas**, no particiones declaradas.

## Lo que este build NO hace

No replica la pata dura del original, que sale de `t_rsk_fct_visioncliente` y es
**solo IBK**. La nuestra sale del RCC y es de todo el sistema, o sea mas ancha.
El resultado es un superconjunto del target del original, y esta bien asi: al
medirlo contra el original en `sql_val_vc`, `solo_tc` dio 0 en los 25 meses
maduros, lo que dice que `dm_sf` ya absorbe todo lo que la pata dura marca.
