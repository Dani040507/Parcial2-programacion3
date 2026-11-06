defmodule Entrada do
  @moduledoc """
  Lectura de archivos en flujo (requisitos generales 1, 2 y 3 del parcial).

  * Se usa `File.stream!/1`: el archivo se lee línea por línea, nunca
    con `File.read!/1`.
  * Todas las transformaciones (numerar, limpiar, filtrar, parsear) son
    perezosas con `Stream`; no se crean listas intermedias.
  * Cada línea se numera ANTES de filtrar, así los reportes de error
    muestran el número de línea física original del archivo.
  """

  @doc """
  Devuelve un Stream perezoso de `{numero_de_linea, contenido}`, sin
  líneas en blanco ni comentarios (primer carácter no blanco igual a #).
  """
  def filas(ruta) do
    ruta
    |> File.stream!()
    # Numeración desde 1, antes de filtrar: conserva la línea física.
    |> Stream.with_index(1)
    # Se quita el salto de línea (\n y \r de archivos de Windows).
    |> Stream.map(fn {linea, numero} ->
      contenido = linea |> String.trim_trailing("\n") |> String.trim_trailing("\r")
      {numero, contenido}
    end)
    # Se descartan líneas vacías y comentarios.
    |> Stream.filter(fn {_numero, contenido} ->
      limpio = String.trim(contenido)
      limpio != "" and not String.starts_with?(limpio, "#")
    end)
  end

  @doc """
  Consume el Stream de tramos. Cada línea mal formada se escribe en
  `errores_tramos.txt` en el momento en que aparece; las válidas se
  devuelven como `%{linea:, contenido:, tramo: %Tramo{}}` en orden.
  Aquí termina la etapa perezosa: a partir de esta lista se depura
  y se arma el grafo.
  """
  def tramos(ruta, errores) do
    ruta
    |> filas()
    |> Stream.map(fn {n, texto} -> {n, texto, Tramo.parse(texto)} end)
    |> Enum.reduce([], fn
      {n, texto, {:ok, tramo}}, acumulado ->
        [%{linea: n, contenido: texto, tramo: tramo} | acumulado]
      {n, texto, {:error, motivo}}, acumulado ->
        Reportes.error_tramo(errores, n, texto, motivo)
        acumulado
    end)
    # Se acumuló al revés (agregar al inicio es O(1)); se restaura el orden.
    |> Enum.reverse()
  end

  @doc "Stream perezoso de consultas: `{linea, texto, {:ok, {origen, destino}} | {:error, motivo}}`."
  def consultas(ruta) do
    ruta
    |> filas()
    |> Stream.map(fn {numero, texto} -> {numero, texto, parse_consulta(texto)} end)
  end

  @doc "Interpreta una línea `origen,destino` de consultas.txt."
  def parse_consulta(texto) do
    case String.split(texto, ",") do
      [a, b] ->
        origen = String.trim(a)
        destino = String.trim(b)
        if origen == "" or destino == "" do
          {:error, "origen y destino no pueden estar vacíos"}
        else
          {:ok, {origen, destino}}
        end
      _ -> {:error, "se esperaban dos campos: origen,destino"}
    end
  end
end
