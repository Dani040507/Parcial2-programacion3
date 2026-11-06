defmodule Validacion do
  @moduledoc """
  Validación previa con recursión: depurar la red (Problema 1).

  Recorre RECURSIVAMENTE la lista de tramos válidos y descarta:
    * bucles: tramos cuyo origen y destino son el mismo centro (A,A);
    * repeticiones de la misma pareja en la misma dirección (A,B otra
      vez), aunque cambien tiempo o costo: se conserva la primera.

  A,B y B,A son direcciones distintas y pueden coexistir.

  Regla del parcial: dentro de este módulo NO se usa Enum ni Stream.
  Por eso incluso invertir la lista se hace con una función propia.

  Cada registro es `%{linea: número físico, contenido: texto, tramo: %Tramo{}}`,
  así el número de línea original viaja junto al struct hasta el reporte.
  """

  @doc """
  Devuelve `{conservados, descartados}` en orden de aparición.
  Cada descartado es `{registro, motivo}`.
  """
  def depurar(registros), do: recorrer(registros, MapSet.new(), [], [])

  # Caso base: no quedan registros. Las listas se acumularon al revés
  # (agregando al inicio), así que se invierten antes de devolverlas.
  defp recorrer([], _vistos, aceptados, descartados) do
    {invertir(aceptados, []), invertir(descartados, [])}
  end

  # Caso recursivo: se analiza el primer registro y se sigue con el resto.
  # `vistos` es un conjunto con las parejas {origen, destino} ya aceptadas.
  defp recorrer([registro | resto], vistos, aceptados, descartados) do
    t = registro.tramo
    pareja = {t.origen, t.destino}

    cond do
      # Bucle A -> A: se descarta.
      t.origen == t.destino ->
        recorrer(resto, vistos, aceptados, [{registro, "bucle: origen y destino iguales"} | descartados])

      # Pareja dirigida ya vista: se descarta y se conserva la primera.
      MapSet.member?(vistos, pareja) ->
        recorrer(resto, vistos, aceptados, [{registro, "pareja dirigida duplicada; se conserva la primera"} | descartados])

      # Tramo nuevo: se acepta y se marca su pareja como vista.
      true ->
        recorrer(resto, MapSet.put(vistos, pareja), [registro | aceptados], descartados)
    end
  end

  # Inversión recursiva de una lista con acumulador (sin Enum.reverse).
  defp invertir([], acumulado), do: acumulado
  defp invertir([primero | resto], acumulado), do: invertir(resto, [primero | acumulado])
end
