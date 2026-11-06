defmodule Reportes do
  @moduledoc """
  Única capa que escribe archivos de salida del Problema 1.

  Requisito general 4 (salidas por flujo): cada archivo se abre en modo
  escritura (se crea o se reemplaza) y se escribe línea por línea a medida
  que se producen los resultados; nunca se arma un único string con todo.

  Salidas:
    * itinerarios.txt       - un bloque por consulta con los óptimos.
    * errores_tramos.txt    - líneas con formato o datos incorrectos.
    * depuracion_tramos.txt - bucles y parejas repetidas descartadas.
    * alcance_centros.txt   - estados del Stream infinito de alcance.
  """

  # Clave interna => nombre del archivo de salida.
  @archivos [
    {:itinerarios, "itinerarios.txt"}, {:errores, "errores_tramos.txt"},
    {:depuracion, "depuracion_tramos.txt"}, {:alcance, "alcance_centros.txt"}
  ]

  @doc """
  Abre (y trunca) las cuatro salidas, ejecuta `funcion` con un mapa
  `%{itinerarios: dispositivo, errores: ..., ...}` y garantiza que todos
  los archivos se cierren, incluso si ocurre un error.
  """
  def con_archivos(directorio, funcion), do: abrir(@archivos, directorio, %{}, funcion)

  # Abre recursivamente un archivo por llamada. El bloque `try ... after`
  # cierra cada archivo al terminar, pase lo que pase.
  defp abrir([], _dir, dispositivos, funcion), do: funcion.(dispositivos)
  defp abrir([{clave, nombre} | resto], dir, dispositivos, funcion) do
    ruta = Path.join(dir, nombre)
    case File.open(ruta, [:write, :utf8]) do
      {:ok, dispositivo} ->
        try do
          abrir(resto, dir, Map.put(dispositivos, clave, dispositivo), funcion)
        after
          File.close(dispositivo)
        end

      {:error, motivo} ->
        {:error, "no se pudo abrir #{ruta}: #{:file.format_error(motivo)}"}
    end
  end

  @doc "Escribe una línea (texto + salto) en el dispositivo abierto."
  def linea(dispositivo, texto) do
    case IO.write(dispositivo, [texto, "\n"]) do
      :ok -> :ok
      {:error, motivo} -> raise "Error al escribir un reporte: #{inspect(motivo)}"
    end
  end

  @doc "Registra en errores_tramos.txt una línea mal formada con su línea física y motivo."
  def error_tramo(dispositivo, linea_fisica, contenido, motivo) do
    linea(dispositivo, "Línea #{linea_fisica}: #{inspect(contenido)} | #{motivo}")
  end

  @doc "Escribe en depuracion_tramos.txt cada tramo descartado: línea física, contenido y motivo."
  def depuracion(dispositivo, descartados) do
    Enum.each(descartados, fn {r, motivo} ->
      linea(dispositivo, "Línea #{r.linea}: #{inspect(r.contenido)} | #{motivo}")
    end)
  end

  @doc "Informa una consulta mal escrita en itinerarios.txt, alcance_centros.txt y pantalla."
  def consulta_invalida(dispositivos, numero, contenido, motivo) do
    texto = "Línea #{numero}: consulta inválida #{inspect(contenido)} | #{motivo}"
    linea(dispositivos.itinerarios, texto)
    linea(dispositivos.alcance, texto)
    IO.puts("Consulta inválida en línea #{numero}: total 0 itinerarios")
  end

  @doc "Informa centros que no existen en la red; no se inicia la búsqueda."
  def desconocidos(dispositivos, origen, destino, faltantes) do
    titulo = "=== #{origen} → #{destino} ==="
    texto = "Centro(s) desconocido(s): #{Enum.join(faltantes, ", ")}; no se inicia la búsqueda."
    linea(dispositivos.itinerarios, titulo)
    linea(dispositivos.itinerarios, texto)
    linea(dispositivos.itinerarios, "Total: 0 itinerarios")
    linea(dispositivos.itinerarios, "")
    linea(dispositivos.alcance, titulo)
    linea(dispositivos.alcance, texto)
    linea(dispositivos.alcance, "")
    IO.puts("#{origen} → #{destino}: 0 itinerarios (centro desconocido)")
  end

  @doc """
  Escribe en alcance_centros.txt los estados distintos del Stream de alcance
  y el paso donde se estabiliza. Si el destino no es alcanzable, lo indica
  con «sin itinerarios».
  """
  def alcance(dispositivo, origen, destino, resultado, alcanzable?) do
    linea(dispositivo, "=== #{origen} → #{destino} ===")
    Enum.each(resultado.estados, fn {paso, centros} ->
      # Los conjuntos no tienen orden; se ordenan para un reporte estable.
      contenido = centros |> MapSet.to_list() |> Enum.sort() |> Enum.join(", ")
      linea(dispositivo, "Paso #{paso}: {#{contenido}}")
    end)
    linea(dispositivo,
      "Estabilización: paso #{resultado.estable_en} (primer estado repetido; " <>
        "el conjunto ya era estable desde el paso #{resultado.estable_en - 1})")
    if not alcanzable? do
      linea(dispositivo, "#{destino} no es alcanzable desde #{origen}: sin itinerarios (no se ejecuta la búsqueda exhaustiva)")
    end
    linea(dispositivo, "")
  end

  @doc """
  Escribe el bloque de una consulta en itinerarios.txt: cada itinerario
  numerado con sus tramos, el total y los tres criterios óptimos
  (con todos los empates). En pantalla muestra el total de la consulta.
  """
  def itinerarios(dispositivo, origen, destino, itinerarios) do
    linea(dispositivo, "=== #{origen} → #{destino} ===")
    if itinerarios == [], do: linea(dispositivo, "Sin itinerarios.")
    # Cada itinerario se escribe en cuanto se recorre: primero el resumen
    # y luego el detalle de sus tramos.
    itinerarios |> Enum.with_index(1) |> Enum.each(fn {it, numero} ->
      linea(dispositivo, "Itinerario #{numero}: #{Enum.join(it.centros, " → ")} | " <>
        "tramos: #{length(it.tramos)} | #{it.minutos} min | costo: #{it.costo}")
      if it.tramos == [], do: linea(dispositivo, "  Sin tramos (origen igual al destino).")
      Enum.each(it.tramos, fn t ->
        linea(dispositivo, "  #{t.origen} → #{t.destino} | #{t.minutos} min | costo: #{t.costo}")
      end)
    end)
    total = length(itinerarios)
    linea(dispositivo, "Total: #{total} itinerarios")
    optimos = Rutas.optimos(itinerarios)
    linea(dispositivo, "Menos tramos: #{indices(optimos.tramos)}")
    linea(dispositivo, "Menor tiempo: #{indices(optimos.tiempo)}")
    linea(dispositivo, "Menor costo: #{indices(optimos.costo)}")
    linea(dispositivo, "")
    # Resumen en pantalla (requisito 5).
    IO.puts("#{origen} → #{destino}: #{total} itinerarios")
  end

  # Formatea la lista de índices óptimos: "1, 3" o "ninguno".
  defp indices([]), do: "ninguno"
  defp indices(lista), do: Enum.join(lista, ", ")
end
