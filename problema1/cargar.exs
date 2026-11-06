# Carga todos los módulos del Problema 1 sin usar Mix.
# El orden importa: primero los structs (Tramo, Itinerario) y después
# los módulos que los usan. main.exs y las pruebas cargan este archivo.
for archivo <- [
      "tramo.exs", "itinerario.exs", "validacion.exs", "grafo.exs",
      "rutas.exs", "alcance.exs", "reportes.exs", "entrada.exs", "aplicacion.exs"
    ] do
  Code.require_file(archivo, __DIR__)
end
