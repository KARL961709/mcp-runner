# explora - contrato de scr_vcnbank_rsk

Read-only, por lote:

    .\Run-Athena.ps1 -SqlDir proyectos/tcnobank/explora

Sirven para poder escribir el build de la tabla calibrada sobre el universo
scoreado. Sin las tres no se escribe una linea de CTAS:

- **01** da el nombre y tipo de cada columna. Los numericos de esta tabla vienen
  como texto (`40_pdraw` los pasa por `TRY_CAST`), asi que el tipo se mide.
- **02** dice hasta donde llega hacia atras y cuanto pesa cada mes. Con ~25M
  filas por mes, la ventana decide si el build corre o agota recursos.
- **03** mide el formato de la llave. `30_drivers` deja anotado que sin la
  restriccion de poblacion el `row_number` ordena 2,000 millones de filas y
  Athena agota recursos: hay que saber contra que se esta uniendo.
