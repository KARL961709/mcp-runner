# sql_val_frontera - hasta donde llega cada fuente

Read-only, se corre por lote:

    .\Run-Athena.ps1 -SqlDir proyectos/tcnobank/sql_val_frontera

Contesta una sola pregunta: **hasta que codmes se puede extender el scoreo.**
El limite lo pone la fuente que cierra ultimo, no la que cierra primero, porque
cada pieza entra con su propio rezago:

| fuente | rezago con que entra |
|---|---|
| RCC (poblacion) | m-2 |
| scr_vcnbank_rsk (pd_raw) | el mes mismo |
| 360 pasivos | [M-6, M-1] |
| PLIN | [M-3, M-1] |
| cuenta sueldo | M-1 |

Un mes M es scoreable si el RCC tiene M, el score tiene M, y las tres fuentes
del nodo tienen al menos M-1. Se cuenta FILAS y no se usa max(): una particion
declarada y vacia dice que el mes existe cuando no hay dato.
