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

## 2. Export del fit + panel (parquet, CON -Bajar)

    .\Go.ps1 -SqlDir proyectos/ecvc/sql_prod -S3Datos "s3://ibk-discovery-riesgos-us-east-1-339712995012-data/discovery/model_owner/B46029/ecvc" -Bajar -LocalDatos "<ruta local, misma que TC pero carpeta EC VC>"

Corre `e00 drop fit -> e01 fit -> e02 drop panel -> e03 panel` y sincroniza `.../ecvc/` (ecvc_fit/ + ecvc_panel/) a -LocalDatos. Primer deploy: los subfolders no existen, no hay que vaciar. Re-corrida: vaciar `.../ecvc/ecvc_fit/` y `.../ecvc/ecvc_panel/` antes.

## Gate CDA (antes de exportar)

Si `i07` muestra **CDA** en volumen relevante y en scope, hay que **re-correr el Recibido** con CDA agregado a los filtros (`02_Logica_nodos.sql:37`, `03_Reproceso_ec_cdd_nodos.sql:60`) y definir sus quintiles de nodo (`02:303-307`) ANTES de exportar. El export lee lo que tenga `ds_ec_cdd_cal`, asi que si se reconstruye con CDA, el mismo `e01/e03` lo baja.
