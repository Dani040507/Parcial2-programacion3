# Punto de entrada del Problema 1 (rutas de entrega en una red dirigida).
#
# Uso:
#   elixir main.exs                 -> lee y escribe en la carpeta de este archivo
#   elixir main.exs <directorio>    -> lee y escribe en <directorio>
#
# Sin argumentos se usa __DIR__ (la carpeta donde está main.exs) y no la
# carpeta actual, para que funcione igual desde la terminal o con el botón
# Run / Code Runner de VS Code, sin importar qué carpeta esté abierta.
#
# Si falta tramos.csv o consultas.txt se informa por pantalla cuál falta y el
# programa termina con código 1, sin excepción sin manejar.
Code.require_file("cargar.exs", __DIR__)

case System.argv() do
  [] ->
    case Aplicacion.ejecutar(__DIR__) do
      :ok -> :ok
      {:error, motivo} -> IO.puts(:stderr, "Error: #{motivo}"); System.halt(1)
    end
  [directorio] ->
    case Aplicacion.ejecutar(directorio) do
      :ok -> :ok
      {:error, motivo} -> IO.puts(:stderr, "Error: #{motivo}"); System.halt(1)
    end
  _ ->
    IO.puts(:stderr, "Uso: elixir main.exs [directorio_de_entradas_y_salidas]")
    System.halt(1)
end
