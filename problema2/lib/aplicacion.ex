defmodule Aplicacion do
  @moduledoc """
  Orquestación del Problema 2. Devuelve el código de salida: 0 si todo
  salió bien y 1 si hubo errores.

  Orden: preparar salidas -> leer paleta y mapa -> validar recursivamente
  -> escribir validacion_mapa.txt -> (solo si no hay errores) calcular
  regiones y escribir regiones.csv, mapa_regiones.svg y resumen.
  """

  @doc "Ejecuta todo el proceso con las rutas dadas."
  def ejecutar(mapa, paleta, dir) do
    resultados = ["validacion_mapa.txt", "regiones.csv", "mapa_regiones.svg", "resumen_regiones.txt"]
    destinos = Enum.map(resultados, &Path.expand(Path.join(dir, &1)))
    # Protección: si una entrada se llama igual que una salida, se borraría.
    if Path.expand(mapa) in destinos or Path.expand(paleta) in destinos do
      IO.puts(:stderr, "Error: una entrada coincide con un archivo de salida")
      1
    else
      case EntradaSalida.preparar(dir) do
        :ok -> procesar(mapa, paleta, dir)
        {:error, error} -> IO.puts(:stderr, "Error: " <> error); 1
      end
    end
  rescue
    e -> IO.puts(:stderr, "Error inesperado: #{Exception.message(e)}"); 1
  end

  # Lee y valida ambos archivos. Se juntan TODOS los errores de la paleta y
  # del mapa y se escriben en validacion_mapa.txt.
  defp procesar(mapa, paleta, dir) do
    lectura_paleta = EntradaSalida.leer(paleta, :paleta)
    lectura_mapa = EntradaSalida.leer(mapa, :mapa)
    {colores, errores_paleta} = case lectura_paleta do
      {:ok, lineas} -> Validacion.paleta(lineas)
      {:error, mensaje} -> {:sin_paleta, [mensaje]}
    end
    {filas, errores_mapa} = case lectura_mapa do
      {:ok, lineas} -> Validacion.mapa(lineas, colores)
      {:error, mensaje} -> {[], [mensaje]}
    end
    errores = errores_paleta ++ errores_mapa
    # Cada error se escribe como su propia línea; no se forma un único string.
    fragmentos = if errores == [], do: ["Validación correcta.\n"], else: Stream.map(errores, &(&1 <> "\n"))
    case EntradaSalida.escribir_fragmentos(dir, "validacion_mapa.txt", fragmentos) do
      {:error, mensaje} -> IO.puts(:stderr, "Error: " <> mensaje); 1
      :ok ->
        if errores != [] do
          # Con errores NO se calculan regiones ni SVG.
          IO.puts(:stderr, "Validación fallida:")
          Enum.each(errores, &IO.puts(:stderr, &1))
          1
        else
          generar(filas, colores, dir)
        end
    end
  end

  # Calcula las regiones y escribe las tres salidas por fragmentos. Si
  # alguna escritura falla, borra las salidas parciales.
  defp generar(filas, colores, dir) do
    regiones = Regiones.encontrar(filas)
    resumen = Salidas.resumen(regiones, filas)
    resultado = with :ok <- EntradaSalida.escribir_fragmentos(dir, "regiones.csv", Salidas.csv(regiones)),
         :ok <- EntradaSalida.escribir_fragmentos(dir, "mapa_regiones.svg", Salidas.svg_fragmentos(filas, colores, regiones)),
         :ok <- EntradaSalida.escribir_fragmentos(dir, "resumen_regiones.txt", resumen) do
      :ok
    end
    case resultado do
      # Resumen en pantalla (requisito 5).
      :ok -> Enum.each(resumen, &IO.write/1); 0
      {:error, mensaje} ->
        Enum.each(["regiones.csv", "mapa_regiones.svg", "resumen_regiones.txt"], fn nombre ->
          case File.rm(Path.join(dir, nombre)) do
            :ok -> :ok
            {:error, :enoent} -> :ok
            {:error, motivo} -> IO.puts(:stderr, "No se pudo retirar #{nombre}: #{inspect(motivo)}")
          end
        end)
        IO.puts(:stderr, "Error: " <> mensaje)
        1
    end
  end
end
