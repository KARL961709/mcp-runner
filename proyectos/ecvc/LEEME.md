# ecvc — calibracion PD Efectivo Credito Vision Cliente

Producto **EC** (sub_producto CDD + EC). Espejo de tcvc/ppvc. Score pd_raw = scr_vcadmbnk (Vision Cliente). Tabla insumo ya construida: `disc_model_owner.ds_ec_cdd_cal`.

## 1. Exploratorias (read-only, vuelven por `_resultados.txt`, SIN -Bajar)

    .\Go.ps1 -SqlDir proyectos/ecvc/sql_val

- `i00` cobertura por codmes (ventana + scoreo 100%).
- `i01` entidades (panel para ciclo/rho: hay SS.FF o EC es IBK-only).
- `i02` sub_producto en ds_ec_cdd_cal (post-filtro CDD/EC).
- `i03` celdas sub_producto x tipo_ingreso x nodo (viabilidad + shrinkage).
- `i04` calce pd_raw vs RD12 por eje.
- `i05` grano (persona-mes vs persona-mes-subproducto).
- `i06` madurez por horizonte.
- `i07` **dominio COMPLETO de ca_tipo_prod sobre `enr_ec_cdd` (pre-filtro): detecta CDA u otros valores que 02/03 excluyen.** Si `enr_ec_cdd` no existe, medir en los desembolsos _tmp.

## 2. Export del fit (parquet, CON -Bajar)

    .\Go.ps1 -SqlDir proyectos/ecvc/sql_prod -S3Datos "s3://ibk-discovery-riesgos-us-east-1-339712995012-data/discovery/model_owner/B46029/ecvc" -Bajar -LocalDatos "<ruta local, misma que TC pero carpeta EC VC>"

Corre `e00 drop fit -> e01 fit` y sincroniza `.../ecvc/ecvc_fit/` a -LocalDatos. Primer deploy: el subfolder no existe, no hay que vaciar. Re-corrida: vaciar `.../ecvc/ecvc_fit/` antes. NO hay panel: EC es IBK-only y row-level, del propio fit salen RD-hist + rho MoM + lambda.

## Alcance: SOLO sub_producto='EC' (decision usuario)

Single-model sobre `sub_producto='EC'` (796k, 88%). **CDD (85k) y CDA (21k) quedan FUERA por decision**, no por bug: i07 confirmo que CDA existe y lo botaba el filtro `in ('CDD','EC')`, pero se calibra solo EC. Por eso el export filtra `sub_producto='EC'` y NO se re-corre el Recibido. Macro: ft/beta sistemica reutilizada de TC (IBK-only); rho MoM y lambda sobre EC IBK.
