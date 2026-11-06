# Problema 2 — regiones y SVG

Proyecto docente sin Mix ni dependencias externas. Se recomienda Elixir 1.12 o posterior.

## Ejecución

```sh
cd problema2
elixir main.exs
# O bien, con rutas explícitas:
elixir main.exs ruta/mapa.txt ruta/paleta.csv ruta/salida
elixir test/test.exs
```

Sin argumentos se usan `mapa.txt`, `paleta.csv` y el directorio actual. Código de salida: 0 si todo es correcto, 1 si hay errores. Se crea el directorio de salida si no existe.

## Entradas

- UTF-8. Se ignoran líneas vacías y comentarios de línea completa cuyo primer carácter no blanco es `#`. Las líneas vacías no son filas; el mapa debe tener al menos una fila. Las líneas físicas se numeran desde 1 antes de filtrarlas.
- El mapa tiene símbolos separados por espacios; cada símbolo es un token no vacío, sin espacios, que no comienza por `#`. Todas las filas deben tener el mismo número positivo de celdas. Filas y columnas se numeran desde 0.
- La paleta no tiene cabecera: `simbolo,nombre,#RRGGBB` por línea; los campos se recortan. No se interpretan comillas CSV ni comas dentro de los campos. El nombre no puede estar vacío, los símbolos no se repiten y `.` debe existir como fondo. Se aceptan hexadecimales en mayúsculas o minúsculas.
- La lectura usa `File.stream!/1`, numera, filtra y convierte cada línea perezosamente con `Stream.map` en sus celdas o campos **antes** de `Enum.to_list`. Cada estructura conserva su línea física; el UTF-8 inválido se marca para informarlo. La validación recorre las estructuras parseadas por recursión propia, sin `Enum` ni `Stream`.

## Salidas

Cada ejecución limpia los cuatro resultados anteriores. **Use un directorio dedicado**: estos nombres se eliminan y recrean. Si una ruta de entrada coincide con una ruta de salida, se rechaza la ejecución antes de limpiar.

- Todas las salidas (`validacion_mapa.txt`, `regiones.csv`, SVG y resumen) se escriben por líneas o fragmentos a partir de Streams (`Salidas.csv/1`, `Salidas.resumen/2`, `Salidas.svg_fragmentos/3`), sin armar un único string.
- `validacion_mapa.txt`: todos los errores detectados o el mensaje de éxito. Si hay errores no se calculan regiones y no quedan los otros resultados anteriores. Se informa si falta una entrada o no se puede leer.
- `regiones.csv`: delimitador `;` y cabecera exacta `id;simbolo;area;perimetro;desde;hasta`. `desde` y `hasta` son las esquinas inclusivas de la caja, en formato `{fila,columna}` y base 0. Los campos que lo necesitan se entrecomillan y se duplican las comillas internas.
- `mapa_regiones.svg`: salida incremental, celdas de 40 × 40 píxeles para todos los símbolos (incluido fondo), bordes de cada componente e ID en su primera celda; contenido XML escapado.
- `resumen_regiones.txt` y pantalla: dimensiones, todas las regiones y **todos los empates** tanto de área máxima como de perímetro máximo, calculados independientemente. Si no hay regiones, ambos indican que no las hay.

Las regiones son componentes conexas de un mismo símbolo mediante vecinos cardinales; el fondo no forma regiones. Los IDs empiezan en 1 y siguen el barrido por fila/columna. El perímetro cuenta lados expuestos, incluidos los límites del mapa y los huecos. Las cajas son inclusivas.

## Ejemplo incluido

La matriz de 5 × 5 es:

```text
A A . B B
A . . B .
. . C . .
C C C . B
C . . B B
```

La paleta es `A,agua,#2563EB`, `B,bosque,#16A34A`, `C,cultivo,#F59E0B` y `.,fondo,#F1F5F9`. Las regiones resultantes son A (área 3, perímetro 8), B (3, 8), C (5, 12) y B (3, 8); C es máxima en ambos criterios. Las dos regiones B solo se tocan diagonalmente. C ocupa `(2,2)`, `(3,0)`, `(3,1)`, `(3,2)`, `(4,0)`.

## Estructura

`main.exs` carga los módulos. `lib/modelos.ex` define `Color` y `Region`; `lib/validacion.ex` valida; `lib/regiones.ex` calcula; `lib/salidas.ex` genera contenidos; `lib/entrada_salida.ex` realiza E/S y `lib/aplicacion.ex` coordina. `test/test.exs` contiene pruebas ExUnit.
