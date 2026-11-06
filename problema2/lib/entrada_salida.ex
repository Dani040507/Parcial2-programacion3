defmodule EntradaSalida do
  @moduledoc """
  Efectos de lectura y escritura del Problema 2.

  * Lectura con File.stream!/1, línea por línea; numeración física antes de
    filtrar; filtrado y conversión perezosos con Stream.
  * Escritura por fragmentos: cada línea o etiqueta se escribe apenas se
    produce.
  """
  @resultados ["validacion_mapa.txt", "regiones.csv", "mapa_regiones.svg", "resumen_regiones.txt"]

  @doc """
  Lee mapa.txt (`:mapa`) o paleta.csv (`:paleta`).
  Devuelve `{:ok, [{campos, línea_física}, ...]}` o `{:error, mensaje}`
  (por ejemplo, si falta el archivo).
  Solo se materializan las estructuras ya convertidas, nunca el texto completo.
  """
  def leer(ruta, tipo) when tipo in [:mapa, :paleta] do
    try do
      datos = File.stream!(ruta)
        |> Stream.with_index(1)
        |> Stream.reject(fn {linea, _num} -> descartar?(linea) end)
        |> Stream.map(fn {linea, num} -> {convertir(linea, tipo), num} end)
        |> Enum.to_list()
      {:ok, datos}
    rescue
      # Archivo faltante u otro error de lectura: se informa sin excepción.
      e in File.Error ->
        if e.reason == :enoent,
          do: {:error, "falta el archivo requerido: #{ruta}"},
          else: {:error, "#{ruta}: #{Exception.message(e)}"}
      e -> {:error, "#{ruta}: #{Exception.message(e)}"}
    end
  end

  # Convierte una línea: el mapa se separa por espacios en símbolos; la
  # paleta se separa por comas en campos recortados.
  defp convertir(linea, tipo) do
    if String.valid?(linea) do
      texto = String.trim(linea)
      case tipo do
        :mapa -> String.split(texto)
        :paleta -> texto |> String.split(",", trim: false) |> Enum.map(&String.trim/1)
      end
    else
      :utf8_invalido
    end
  end

  # true para líneas en blanco o comentarios (primer carácter no blanco #).
  defp descartar?(linea) do
    if String.valid?(linea) do
      texto = String.trim(linea)
      texto == "" or String.starts_with?(texto, "#")
    else
      false
    end
  end

  @doc "Crea el directorio de salida y borra los resultados de la ejecución anterior."
  def preparar(dir) do
    with :ok <- File.mkdir_p(dir) do
      Enum.reduce_while(@resultados, :ok, fn nombre, :ok ->
        case File.rm(Path.join(dir, nombre)) do
          :ok -> {:cont, :ok}
          {:error, :enoent} -> {:cont, :ok}
          {:error, motivo} -> {:halt, {:error, "no se pudo retirar #{nombre}: #{inspect(motivo)}"}}
        end
      end)
    else
      {:error, motivo} -> {:error, "no se pudo crear #{dir}: #{inspect(motivo)}"}
    end
  end

  @doc """
  Abre `dir/nombre` en modo escritura (crea o reemplaza) y escribe los
  fragmentos uno por uno a medida que el Stream los entrega.
  """
  def escribir_fragmentos(dir, nombre, fragmentos) do
    ruta = Path.join(dir, nombre)
    try do
      case File.open(ruta, [:write, :binary], fn io ->
        Enum.reduce_while(fragmentos, :ok, fn fragmento, :ok ->
          case IO.binwrite(io, fragmento) do
            :ok -> {:cont, :ok}
            {:error, motivo} -> {:halt, {:error, motivo}}
          end
        end)
      end) do
        {:ok, :ok} -> :ok
        {:ok, {:error, motivo}} -> {:error, "no se pudo escribir #{nombre}: #{inspect(motivo)}"}
        {:error, motivo} -> {:error, "no se pudo abrir #{nombre}: #{inspect(motivo)}"}
      end
    rescue
      e -> {:error, "no se pudo escribir #{nombre}: #{Exception.message(e)}"}
    end
  end
end
