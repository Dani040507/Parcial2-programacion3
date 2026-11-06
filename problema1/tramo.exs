defmodule Tramo do
  @moduledoc """
  Struct que representa un tramo DIRIGIDO de la red de distribución.

  Campos:
    * `origen`  - nombre del centro de salida (texto).
    * `destino` - nombre del centro de llegada (texto).
    * `minutos` - tiempo del tramo; entero mayor que cero.
    * `costo`   - costo del tramo; entero mayor que cero.

  `parse/1` es una función pura: recibe el texto de UNA línea de
  `tramos.csv` y devuelve `{:ok, %Tramo{}}` o `{:error, motivo}`.
  No escribe en archivos ni en pantalla; eso lo hace el módulo Reportes.
  """
  @enforce_keys [:origen, :destino, :minutos, :costo]
  defstruct [:origen, :destino, :minutos, :costo]

  @doc """
  Convierte una línea `origen,destino,minutos,costo` en un tramo.

  Ejemplos:
      Tramo.parse("A,B,8,5")  #=> {:ok, %Tramo{origen: "A", destino: "B", minutos: 8, costo: 5}}
      Tramo.parse("A,B,0,5")  #=> {:error, "minutos debe ser un entero positivo"}
      Tramo.parse("A,B")      #=> {:error, "se esperaban cuatro campos: ..."}
  """
  def parse(linea) when is_binary(linea) do
    # 1. Se separa la línea por comas; debe haber exactamente 4 campos.
    case String.split(linea, ",") do
      [origen, destino, minutos, costo] ->
        origen = String.trim(origen)
        destino = String.trim(destino)

        cond do
          # 2. Los nombres de los centros no pueden quedar vacíos.
          origen == "" or destino == "" ->
            {:error, "origen y destino no pueden estar vacíos"}

          true ->
            # 3. `with` encadena las dos conversiones numéricas: si alguna
            #    devuelve {:error, _}, ese error sale directamente.
            with {:ok, minutos} <- positivo(minutos, "minutos"),
                 {:ok, costo} <- positivo(costo, "costo") do
              {:ok, %Tramo{origen: origen, destino: destino, minutos: minutos, costo: costo}}
            end
        end

      _ ->
        {:error, "se esperaban cuatro campos: origen,destino,minutos,costo"}
    end
  end

  # Convierte un texto en entero positivo. Integer.parse devuelve
  # {número, resto}; exigimos resto "" para rechazar casos como "2x".
  defp positivo(texto, nombre) do
    case Integer.parse(String.trim(texto)) do
      {numero, ""} when numero > 0 -> {:ok, numero}
      _ -> {:error, "#{nombre} debe ser un entero positivo"}
    end
  end
end
