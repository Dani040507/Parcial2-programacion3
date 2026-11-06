# Parcial 2 — Programación III (Universidad del Quindío)

Programación funcional con Elixir. Problemas elegidos: **1** (rutas de entrega, structs y Stream infinito) y **2** (regiones en un mapa y SVG, structs). Es una combinación válida según el enunciado (1 y 2).

Requisitos: Elixir 1.12 o posterior. No se usa Mix ni dependencias externas.

Cada módulo tiene `@moduledoc`, cada función pública tiene `@doc` y las funciones privadas y los pasos importantes llevan comentarios `#` que explican qué hacen y por qué.

> Sin argumentos, cada `main.exs` lee y escribe en **su propia carpeta**, así que también funciona con el botón Run / Code Runner de VS Code aunque esté abierta la carpeta principal. Para los casos de prueba (que llevan argumentos) usen la terminal dentro de `problema1` o `problema2`.

## Problema 1 — Rutas de entrega

```sh
cd problema1
elixir main.exs                          # caso válido (datos del PDF)
elixir main.exs casos_prueba/invalido    # caso inválido
elixir main.exs casos_prueba/limite      # caso límite
elixir test/problema1_test.exs           # pruebas automáticas
```

Salidas (en la carpeta que se procesa): `itinerarios.txt`, `errores_tramos.txt`, `depuracion_tramos.txt`, `alcance_centros.txt`.

| Archivo | Qué contiene |
|---|---|
| `tramo.exs`, `itinerario.exs` | Structs `%Tramo{}` y `%Itinerario{}`; `Tramo.parse/1` |
| `entrada.exs` | Lectura con `File.stream!/1` y transformaciones perezosas |
| `validacion.exs` | Depuración recursiva (bucles y parejas repetidas), sin Enum ni Stream |
| `grafo.exs` | Grafo dirigido y un paso de alcance |
| `rutas.exs` | DFS recursiva con backtracking y óptimos con empates |
| `alcance.exs` | Stream infinito de centros alcanzables y su punto fijo |
| `reportes.exs` | Escritura línea por línea de los cuatro reportes |
| `aplicacion.exs`, `main.exs`, `cargar.exs` | Orquestación y punto de entrada |

## Problema 2 — Regiones y SVG

```sh
cd problema2
elixir main.exs                                                         # caso válido (PDF)
elixir main.exs casos_prueba/invalido/mapa.txt casos_prueba/invalido/paleta.csv casos_prueba/invalido
elixir main.exs casos_prueba/limite/mapa.txt casos_prueba/limite/paleta.csv casos_prueba/limite
elixir test/test.exs                                                    # pruebas automáticas
```

Salidas: `validacion_mapa.txt`, `regiones.csv`, `mapa_regiones.svg`, `resumen_regiones.txt`. El SVG se abre en cualquier navegador.

| Archivo | Qué contiene |
|---|---|
| `lib/modelos.ex` | Structs `%Color{}` y `%Region{}` |
| `lib/entrada_salida.ex` | Lectura con `File.stream!/1` y escritura por fragmentos |
| `lib/validacion.ex` | Validación recursiva de mapa y paleta, sin Enum ni Stream |
| `lib/regiones.ex` | `recorrer/5` y `explorar/6`: regiones, área, perímetro y caja |
| `lib/salidas.ex` | CSV, resumen y SVG como Streams de fragmentos |
| `lib/aplicacion.ex`, `main.exs` | Orquestación y punto de entrada |

## Casos de prueba incluidos

| Problema | Caso | Qué prueba |
|---|---|---|
| 1 | válido (`tramos.csv`, `consultas.txt`) | Ejemplo del PDF: A→D con 4 itinerarios, B→A sin itinerarios |
| 1 | `casos_prueba/invalido` | Minutos 0, campos faltantes, texto en número, origen vacío, bucle C,C, pareja A,C repetida, centro Z inexistente y consulta con `;` |
| 1 | `casos_prueba/limite` | Origen igual a destino (A,A), ciclo A↔B, destino inalcanzable desde un nodo sin salidas (C,A) |
| 2 | válido (`mapa.txt`, `paleta.csv`) | Ejemplo del PDF: 4 regiones, C es la de mayor área y perímetro |
| 2 | `casos_prueba/invalido` | Fila de distinta longitud, símbolo sin color, color sin `#`, símbolo repetido, falta el fondo `.` |
| 2 | `casos_prueba/limite` | Mapa 1×1 que solo tiene fondo: 0 regiones y SVG de 40×40 |

Cada carpeta tiene su propio README con formatos de entrada, supuestos y decisiones de diseño.
