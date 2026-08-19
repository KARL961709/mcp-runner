# sql_val_nodo — validación del nodo

## Frontera de las fuentes (01–05)

Read-only, por lote. Miden hasta dónde llega cada fuente del nodo y si la tabla
lo refleja.

    .\Run-Athena.ps1 -SqlDir proyectos/tcnobank/sql_val_nodo

## Match contra el csv recibido (06–08)

Compara el nodo construido contra `Recibidos2/nodos.csv`, que es la fuente
original. **En SQL**, que es el lenguaje en el que corre el despliegue — el
equivalente en Python vive en `Programas/analisis/match_nodos.py` y da los
mismos números.

### Paso previo, una sola vez

1. Subir `Data/nodos_recibido.tsv` a
   `s3://ibk-discovery-riesgos-us-east-1-339712995012-data/discovery/model_owner/B46029/tcnb/nodos_recibido/`
   **Un solo archivo en esa carpeta**: la tabla externa lee todo lo que encuentre.

2. Montar la tabla externa:

       .\Run-Athena.ps1 -SqlDir proyectos/tcnobank/sql_prod/04_aux -Only 90_ddl_nodos_recibido.sql

Va como `.tsv` y no como el `.csv` original porque ese viene separado por punto
y coma y con comillas dobles: las dos cosas rompen el G0 del puente. Convertirlo
a tab no pierde nada — medido, ninguna celda contiene tabs, saltos ni comillas,
y la relectura es idéntica al original.

Para rehacerlo:

    python -c "import pandas as pd; d=pd.read_csv('Recibidos2/nodos.csv',sep=';',dtype=str); d.to_csv('ENTREGA_TCNB/Data/nodos_recibido.tsv',sep='\t',index=False)"

### Qué tiene que dar

Medido en local el 2026-08-14, sobre las 16 651 filas que cruzan:

| query | resultado esperado |
|---|---|
| **06** | `ok_pasivos`, `ok_plinero`, `ok_plin_f1`, `ok_plin_f2` = **16 651** (100%). `ok_cta_sueldo` = **15 210** (91,35%). `ok_nodo` = **15 544** (93,35%) |
| **07** | la diagonal suma 15 544. Y en la partición `cs coincide` **toda** la masa cae en la diagonal: 15 210 de 15 210 |
| **08** | `cruzan_llave_y_mes` = 16 651 · `solo_falla_el_mes` = 2 013 · `llave_inexistente` = **0** |

La 07 es la que cierra el diagnóstico: si en `cs coincide` hay algo fuera de la
diagonal, el problema **no** es cuenta sueldo y hay que volver a mirar las ramas.

Un detalle que la 06 resuelve y conviene no perder: `FLG_PLINERO_U3M` del csv es
**categórico** —`00.NO_PLIN` y variantes son el cero—, no un 0/1. Compararlo
directo contra nuestro entero daría 0% y parecería un error del nodo cuando es
de formato.

## Limpieza

    .\Run-Athena.ps1 -SqlDir proyectos/tcnobank/sql_prod/00_reset -Only r025_drop_nodos_recibido.sql

La tabla externa no borra el archivo de S3, solo la definición.
