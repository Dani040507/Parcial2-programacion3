defmodule Itinerario do
  @moduledoc """
  Struct que representa un camino simple encontrado por la búsqueda.

  Campos:
    * `centros` - lista ordenada de centros visitados, p. ej. ["A", "B", "D"].
    * `minutos` - suma de los minutos de todos sus tramos.
    * `costo`   - suma de los costos de todos sus tramos.
    * `tramos`  - lista de structs %Tramo{} usados, en el mismo orden.
                  El número de tramos del itinerario es length(tramos).
  """
  @enforce_keys [:centros, :minutos, :costo]
  defstruct [:centros, :minutos, :costo, tramos: []]
end
