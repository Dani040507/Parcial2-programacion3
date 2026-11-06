# Punto de entrada del Problema 2 (regiones en un mapa de colores y SVG).
#
# Uso:
#   elixir main.exs                                  -> mapa.txt y paleta.csv de esta carpeta
#   elixir main.exs <mapa> <paleta> <dir_salida>     -> rutas explícitas
#
# Sin argumentos se usa __DIR__ (la carpeta donde está main.exs) y no la
# carpeta actual, para que funcione igual con el botón Run / Code Runner.
# El código de salida es 0 si todo salió bien y 1 si hubo errores.
Code.require_file("lib/modelos.ex", __DIR__)
Code.require_file("lib/validacion.ex", __DIR__)
Code.require_file("lib/regiones.ex", __DIR__)
Code.require_file("lib/salidas.ex", __DIR__)
Code.require_file("lib/entrada_salida.ex", __DIR__)
Code.require_file("lib/aplicacion.ex", __DIR__)
case System.argv() do
  [] -> System.halt(Aplicacion.ejecutar(Path.join(__DIR__, "mapa.txt"), Path.join(__DIR__, "paleta.csv"), __DIR__))
  [mapa, paleta, salida] -> System.halt(Aplicacion.ejecutar(mapa, paleta, salida))
  _ ->
    IO.puts(:stderr, "Uso: elixir main.exs [mapa.txt paleta.csv directorio_salida]")
    System.halt(1)
end
