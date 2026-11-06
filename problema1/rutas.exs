defmodule Rutas do
  @moduledoc """
  Búsqueda recursiva (en profundidad, DFS) de TODOS los itinerarios simples
  entre un origen y un destino, y cálculo de los itinerarios óptimos.

  Un itinerario es simple si no repite centros. Solo se avanza en la
  dirección de cada tramo. La recursión explora un tramo, avanza al
  siguiente centro y, al volver, prueba el siguiente tramo (backtracking).
  """

  @doc "Devuelve la lista de %Itinerario{} en el orden en que la DFS los encuentra."
  def buscar(grafo, origen, destino) do
    # Estado inicial: estamos en el origen, ya visitado, sin tramos,
    # con 0 minutos y costo 0.
    dfs(grafo, origen, destino, MapSet.new([origen]), [origen], [], 0, 0)
  end

  # dfs/8 recibe:
  #   actual    - centro donde estamos
  #   destino   - centro al que queremos llegar
  #   visitados - MapSet de centros del camino actual (evita repetir)
  #   centros   - camino recorrido, guardado al revés para agregar en O(1)
  #   tramos    - tramos usados, también al revés
  #   minutos, costo - totales acumulados hasta aquí
  #
  # CASO BASE: llegamos al destino. Se devuelve una lista con un único
  # itinerario; las listas se invierten para dejarlas en orden normal.
  defp dfs(_grafo, actual, destino, _visitados, centros, tramos, minutos, costo)
       when actual == destino do
    [%Itinerario{centros: Enum.reverse(centros), tramos: Enum.reverse(tramos),
                 minutos: minutos, costo: costo}]
  end

  # CASO RECURSIVO: todavía no llegamos; se exploran los tramos que salen
  # del centro actual.
  defp dfs(grafo, actual, destino, visitados, centros, tramos, minutos, costo) do
    explorar(Grafo.salientes(grafo, actual), grafo, destino, visitados,
             centros, tramos, minutos, costo)
  end

  # explorar/8 recorre RECURSIVAMENTE la lista de tramos salientes.
  # Caso base: no quedan tramos por probar -> no hay más caminos.
  defp explorar([], _grafo, _destino, _visitados, _centros, _tramos, _minutos, _costo), do: []

  # Caso recursivo: se toma el primer tramo `t`.
  defp explorar([t | resto], grafo, destino, visitados, centros, tramos, minutos, costo) do
    por_tramo =
      if MapSet.member?(visitados, t.destino) do
        # Su destino ya está en el camino: tomarlo crearía un ciclo.
        []
      else
        # Se avanza por `t`: se marca su destino, se agrega al camino y se
        # suman sus minutos y su costo. dfs devuelve los caminos que salen
        # de aquí hasta el destino.
        dfs(grafo, t.destino, destino, MapSet.put(visitados, t.destino),
            [t.destino | centros], [t | tramos], minutos + t.minutos, costo + t.costo)
      end

    # BACKTRACKING: con el MISMO estado de antes (sin `t`) se prueban los
    # demás tramos, y se unen sus resultados con los encontrados por `t`.
    por_tramo ++ explorar(resto, grafo, destino, visitados, centros, tramos, minutos, costo)
  end

  @doc """
  Para cada criterio devuelve los números (desde 1) de TODOS los
  itinerarios empatados en el mínimo: `%{tramos: [...], tiempo: [...], costo: [...]}`.
  """
  def optimos([]), do: %{tramos: [], tiempo: [], costo: []}
  def optimos(itinerarios) do
    # Se numeran los itinerarios: [{itinerario, 1}, {itinerario, 2}, ...]
    indexados = Enum.with_index(itinerarios, 1)
    %{
      tramos: indices_minimos(indexados, fn i -> length(i.tramos) end),
      tiempo: indices_minimos(indexados, fn i -> i.minutos end),
      costo: indices_minimos(indexados, fn i -> i.costo end)
    }
  end

  # Recibe una función `valor` que extrae el criterio (tramos, minutos o
  # costo). Primero se calcula el mínimo; luego se conservan TODOS los
  # índices cuyo valor es igual a ese mínimo (así se guardan los empates).
  defp indices_minimos(indexados, valor) do
    minimo = indexados |> Enum.map(fn {it, _} -> valor.(it) end) |> Enum.min()
    for {it, indice} <- indexados, valor.(it) == minimo, do: indice
  end
end
