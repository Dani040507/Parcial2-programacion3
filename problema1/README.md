# Problema 1 — Rutas de entrega en una red dirigida

Proyecto didáctico de Elixir sin dependencias externas ni Mix. Contiene exactamente los datos de ejemplo del PDF en `tramos.csv` y `consultas.txt`.

## Ejecutar

Instale Elixir/OTP, descomprima el ZIP y, desde la carpeta `problema1/`, ejecute:

```sh
elixir main.exs
```

También puede usar `elixir main.exs /ruta/al/directorio`, que lee y escribe en ese directorio. `cargar.exs` utiliza `Code.require_file` para cargar los módulos en el orden necesario. Antes de abrir (y truncar) las salidas se comprueba que existan `tramos.csv` y `consultas.txt`; si falta alguno se nombra en un error y el programa termina con código 1, sin excepción no manejada.

### Entradas

- `tramos.csv`: `origen,destino,minutos,costo`; nombres no vacíos y minutos/costo enteros mayores que cero. Sin cabecera (se permite una cabecera comentada con `#`). Los nombres distinguen mayúsculas y minúsculas. No se admiten campos CSV entrecomillados ni comas dentro de nombres.
- `consultas.txt`: `origen,destino`. Se ignoran líneas vacías y comentarios cuyo primer carácter no blanco es `#`. Cada error y descarte conserva la línea física original. Consultas mal formadas se informan en los dos reportes de consultas.

Las transformaciones de lectura usan `File.stream!/1` y operaciones `Stream` perezosas; después se materializan los tramos para la depuración y el grafo. Los centros conocidos son los extremos de tramos **conservados**; un centro presente solo en un bucle descartado no forma parte del grafo. Un centro desconocido se informa sin iniciar el alcance ni la búsqueda.

### Salidas (se reemplazan en cada ejecución)

- `errores_tramos.txt`: contenido, línea física y motivo de cada tramo mal formado.
- `depuracion_tramos.txt`: contenido, línea y motivo de bucles y parejas dirigidas repetidas; se conserva la primera pareja aun cuando varíen tiempo o costo. La dirección inversa es diferente.
- `alcance_centros.txt`: estados distintos y paso en que aparece por primera vez el mismo conjunto del paso anterior. Si falta un centro o la consulta es inválida, se indica en lugar de calcular el alcance.
- `itinerarios.txt`: consultas, detalle de cada tramo, totales, y números de **todos** los itinerarios empatados en cada mínimo. El total de cada consulta también se muestra en pantalla.

Los archivos se abren en modo escritura y se escriben por líneas o fragmentos, no mediante un único texto global. Si ocurre un error de lectura o escritura, los archivos pueden quedar parcialmente escritos. No guarde información propia en archivos con esos nombres dentro del directorio de ejecución.

## Pruebas

```sh
elixir test/problema1_test.exs
```

La suite ExUnit cubre parseo válido e inválido, líneas físicas, bucles y duplicados dirigidos, muestra del PDF y sus cuatro rutas, empates, ciclos, destinos inalcanzables, centro desconocido, entradas vacías, archivos ausentes y origen igual a destino. Para evaluar entradas de mayor tamaño, tenga en cuenta que enumerar todos los caminos simples puede requerir tiempo y memoria exponenciales.

## Diseño y supuestos

- `Tramo` e `Itinerario` son structs; el último añade `tramos` para conservar datos detallados.
- `Validacion.depurar/1` es recursiva y pura, sin `Enum` ni `Stream` en sus funciones. `Grafo` conserva el orden de entrada; `Rutas` hace DFS recursiva y no repite centros de un camino.
- **Origen igual a destino:** si ese centro existe en el grafo, hay un itinerario válido de cero tramos, cero minutos y costo cero. Si es desconocido, se informa como tal y no se busca.
- `Alcance.stream/2` es infinito: comienza con `{origen}` y añade vecinos acumulativamente. `Alcance.estabilizar/2` lo consume hasta la primera repetición consecutiva y devuelve solo estados distintos. Como el conjunto crece monótonamente y el grafo tiene un número finito de centros, necesariamente alcanza un punto fijo, incluso si hay ciclos. En `alcance_centros.txt` se informa el paso del primer estado repetido y también desde qué paso el conjunto ya era estable (p. ej., si el paso 2 repite el 1: «paso 2», estable desde el paso 1).
- Si el destino no pertenece al conjunto final, se omite la DFS exhaustiva y se escribe «sin itinerarios» tanto en `alcance_centros.txt` como en `itinerarios.txt`. La escritura está separada en `Reportes` y la lectura en `Entrada`; la orquestación reside en `Aplicacion`.

Para el ejemplo del PDF, A → D tiene cuatro itinerarios: mínimos por tramos 1 y 3, por tiempo 1 y por costo 3. B → A no tiene itinerarios.
