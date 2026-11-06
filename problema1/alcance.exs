defmodule Alcance do
  @moduledoc """
  Stream infinito de conjuntos de centros alcanzables (Problema 1).

  * Paso 0: solo el origen.
  * Paso n+1: el conjunto del paso n más todos los destinos de los tramos
    que salen de sus centros.

  ¿Por qué converge aunque el Stream sea infinito?
    1. Los conjuntos solo CRECEN (o quedan iguales): nunca se quita un centro.
    2. El grafo tiene un número FINITO de centros, así que el conjunto no
       puede crecer para siempre.
    3. Cuando un paso no agrega nada, el siguiente tampoco agregará (se
       calcula con los mismos centros): es un punto fijo.
  Por eso, aunque Stream.iterate define una secuencia infinita, al ser
  perezosa solo se calculan los pasos que se consumen, y el consumo se
  detiene en el primer estado repetido. Hay como mucho (centros + 1) pasos.
  """

  @doc "Stream INFINITO y perezoso de `{paso, conjunto_de_centros}`."
  def stream(grafo, origen) do
    # Stream.iterate(inicial, f) produce: inicial, f(inicial), f(f(inicial)), ...
    # No calcula nada hasta que alguien consume elementos.
    Stream.iterate({0, MapSet.new([origen])}, fn {paso, centros} ->
      {paso + 1, Grafo.ampliar(grafo, centros)}
    end)
  end

  @doc """
  Consume el Stream solo hasta el primer estado repetido consecutivo.

  Devuelve `%{estados: [{paso, conjunto}, ...] distintos,
             estable_en: paso del primer estado repetido,
             centros: conjunto final}`.
  """
  def estabilizar(grafo, origen) do
    stream(grafo, origen)
    # reduce_while recorre el Stream; con {:halt, _} deja de pedir elementos,
    # así que los pasos siguientes nunca se calculan.
    |> Enum.reduce_while({nil, []}, fn {paso, centros}, {anterior, distintos} ->
      if anterior != nil and MapSet.equal?(anterior, centros) do
        # Igual al paso anterior: punto fijo encontrado, se detiene.
        {:halt, %{estados: Enum.reverse(distintos), estable_en: paso, centros: centros}}
      else
        # Estado nuevo: se guarda y se pide el siguiente.
        {:cont, {centros, [{paso, centros} | distintos]}}
      end
    end)
  end
end
