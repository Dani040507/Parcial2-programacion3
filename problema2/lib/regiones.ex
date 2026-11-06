defmodule Regiones do
  @moduledoc """
  Cálculo de regiones del mapa (Problema 2). Funciones puras.

  Se usan dos funciones recursivas, como pide el enunciado:
    * `recorrer/5` - recorre todas las casillas en orden (fila, columna) y
      empieza una región nueva en cada casilla aún no visitada.
    * `explorar/6` - a partir de una casilla, explora sus vecinos del mismo
      símbolo hasta completar la región (relleno por inundación).
  Un único conjunto `visitadas` garantiza que ninguna casilla se recorra
  dos veces.
  """

  # Desplazamientos cardinales: arriba, izquierda, derecha, abajo.
  @direcciones [{-1, 0}, {0, -1}, {0, 1}, {1, 0}]

  @doc "Las cuatro coordenadas vecinas (pueden quedar fuera del mapa)."
  def vecinos({r, c}), do: Enum.map(@direcciones, fn {dr, dc} -> {r + dr, c + dc} end)

  @doc "Convierte la lista de filas en un mapa `{fila, columna} => símbolo`."
  def indice(filas) do
    for {fila, r} <- Enum.with_index(filas), {s, c} <- Enum.with_index(fila),
      into: %{}, do: {{r, c}, s}
  end

  @doc "Devuelve la lista de %Region{} con IDs desde 1 en orden de barrido."
  def encontrar(filas) do
    mapa = indice(filas)
    # Todas las posiciones en orden: (0,0), (0,1), ..., (1,0), ...
    posiciones = for {fila, r} <- Enum.with_index(filas), {_s, c} <- Enum.with_index(fila), do: {r, c}
    recorrer(posiciones, mapa, MapSet.new(), 1, [])
  end

  # recorrer/5 - Caso base: no quedan casillas; se devuelven las regiones
  # en orden (se acumularon al revés).
  defp recorrer([], _mapa, _visitadas, _id, regiones), do: Enum.reverse(regiones)

  # recorrer/5 - Caso recursivo: se analiza la casilla `p`.
  defp recorrer([p | resto], mapa, visitadas, id, regiones) do
    s = Map.fetch!(mapa, p)
    if s == "." or MapSet.member?(visitadas, p) do
      # Fondo o casilla que ya pertenece a una región: se salta.
      recorrer(resto, mapa, visitadas, id, regiones)
    else
      # Casilla nueva: se explora su región completa.
      {visitadas, celdas, perimetro} = explorar([p], mapa, s, visitadas, [], 0)
      celdas = Enum.sort(celdas)
      # Caja envolvente: mínimos y máximos de filas y columnas.
      [{r0, c0} | _] = celdas
      {rmin, rmax, cmin, cmax} = Enum.reduce(celdas, {r0, r0, c0, c0}, fn {r, c}, {a, b, d, e} ->
        {min(a, r), max(b, r), min(d, c), max(e, c)}
      end)
      region = %Region{id: id, simbolo: s, celdas: celdas, area: length(celdas), perimetro: perimetro,
        fila_min: rmin, fila_max: rmax, columna_min: cmin, columna_max: cmax}
      # Se continúa con el resto, con el conjunto de visitadas actualizado
      # y el siguiente ID.
      recorrer(resto, mapa, visitadas, id + 1, [region | regiones])
    end
  end

  # explorar/6 usa una lista de casillas PENDIENTES (como una pila).
  # Caso base: no hay pendientes -> la región está completa.
  defp explorar([], _mapa, _s, visitadas, celdas, perimetro), do: {visitadas, celdas, perimetro}

  # Caso recursivo: se toma la primera casilla pendiente.
  defp explorar([p | pendientes], mapa, s, visitadas, celdas, perimetro) do
    if MapSet.member?(visitadas, p) do
      # Ya se había agregado (llegó por dos caminos): no se cuenta dos veces.
      explorar(pendientes, mapa, s, visitadas, celdas, perimetro)
    else
      visitadas = MapSet.put(visitadas, p)
      # Vecinos con el MISMO símbolo. Map.get devuelve nil fuera del mapa,
      # así que el borde nunca se considera igual.
      iguales = Enum.filter(vecinos(p), &(Map.get(mapa, &1) == s))
      # Perímetro: de los 4 lados de la casilla, los que NO tocan una casilla
      # igual dan al borde o a otro símbolo -> suman 4 - iguales.
      # Los vecinos iguales se agregan a pendientes para explorarlos.
      explorar(iguales ++ pendientes, mapa, s, visitadas, [p | celdas], perimetro + 4 - length(iguales))
    end
  end

  @doc """
  Devuelve `{regiones_de_mayor_area, regiones_de_mayor_perimetro}`,
  conservando todos los empates.
  """
  def extremos([]), do: {[], []}
  def extremos(regiones) do
    area_max = regiones |> Enum.map(& &1.area) |> Enum.max()
    perimetro_max = regiones |> Enum.map(& &1.perimetro) |> Enum.max()
    {Enum.filter(regiones, &(&1.area == area_max)), Enum.filter(regiones, &(&1.perimetro == perimetro_max))}
  end
end
