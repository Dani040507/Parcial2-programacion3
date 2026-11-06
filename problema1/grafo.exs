defmodule Grafo do
  @moduledoc """
  Grafo dirigido construido con los tramos que sobrevivieron a la depuración.

  * `adyacencias` - mapa `centro => [tramos que salen de él]`, en el mismo
    orden del archivo. Ese orden hace que la búsqueda sea reproducible.
  * `centros`     - conjunto (MapSet) de todos los centros conocidos.

  El grafo se arma DESPUÉS de consumir la transformación perezosa de
  líneas, como pide el enunciado.
  """
  defstruct adyacencias: %{}, centros: MapSet.new()

  @doc "Construye el grafo a partir de los registros conservados por Validacion.depurar/1."
  def construir(registros) do
    {ady, centros} =
      Enum.reduce(registros, {%{}, MapSet.new()}, fn %{tramo: t}, {ady, centros} ->
        # Se agrega el tramo al inicio de la lista de su origen (O(1)).
        ady = Map.update(ady, t.origen, [t], fn anteriores -> [t | anteriores] end)
        centros = centros |> MapSet.put(t.origen) |> MapSet.put(t.destino)
        {ady, centros}
      end)

    # Como se agregó al inicio, cada lista quedó invertida: se reordena.
    ordenadas = Map.new(ady, fn {origen, invertidas} -> {origen, Enum.reverse(invertidas)} end)
    %Grafo{adyacencias: ordenadas, centros: centros}
  end

  @doc "¿El centro aparece en algún tramo conservado?"
  def existe?(grafo, centro), do: MapSet.member?(grafo.centros, centro)

  @doc "Tramos que salen de `centro` (lista vacía si no tiene salidas)."
  def salientes(grafo, centro), do: Map.get(grafo.adyacencias, centro, [])

  @doc """
  Un paso del alcance: al conjunto `alcanzados` le agrega todos los
  destinos de los tramos que salen de sus centros. Lo usa Alcance.stream/2.
  """
  def ampliar(grafo, alcanzados) do
    Enum.reduce(alcanzados, alcanzados, fn centro, acumulado ->
      Enum.reduce(salientes(grafo, centro), acumulado, fn tramo, conjunto ->
        MapSet.put(conjunto, tramo.destino)
      end)
    end)
  end
end
