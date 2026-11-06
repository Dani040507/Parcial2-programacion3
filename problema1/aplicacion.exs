defmodule Aplicacion do
  @moduledoc """
  Orquestación del Problema 1. Une todas las etapas en este orden:

    1. Comprueba que existan tramos.csv y consultas.txt.
    2. Lee los tramos en flujo (Entrada) y reporta los mal formados.
    3. Depura la red recursivamente (Validacion).
    4. Construye el grafo dirigido (Grafo).
    5. Para cada consulta: alcance con Stream infinito (Alcance) y,
       solo si el destino es alcanzable, búsqueda exhaustiva (Rutas).
    6. Escribe todos los reportes (Reportes).
  """

  @doc "Procesa los dos archivos del directorio y devuelve :ok o {:error, descripción}."
  def ejecutar(directorio) do
    requeridos = ["tramos.csv", "consultas.txt"]
    # Se verifica ANTES de abrir las salidas, para no truncarlas en vano.
    faltantes = Enum.reject(requeridos, &File.regular?(Path.join(directorio, &1)))

    if faltantes == [] do
      procesar(directorio)
    else
      {:error, "falta(n) archivo(s) requerido(s) en #{directorio}: #{Enum.join(faltantes, ", ")}"}
    end
  end

  # Con los cuatro archivos de salida abiertos, ejecuta todo el proceso.
  # Los errores de archivo se convierten en {:error, mensaje}; así no
  # termina con una excepción sin manejar.
  defp procesar(directorio) do
    Reportes.con_archivos(directorio, fn archivos ->
      try do
        registros = Entrada.tramos(Path.join(directorio, "tramos.csv"), archivos.errores)
        {conservados, descartados} = Validacion.depurar(registros)
        Reportes.depuracion(archivos.depuracion, descartados)
        grafo = Grafo.construir(conservados)

        # Las consultas también se leen en flujo y se procesan una a una.
        Path.join(directorio, "consultas.txt")
        |> Entrada.consultas()
        |> Enum.each(fn
          {n, texto, {:error, motivo}} ->
            Reportes.consulta_invalida(archivos, n, texto, motivo)
          {_n, _texto, {:ok, {origen, destino}}} ->
            procesar_consulta(grafo, archivos, origen, destino)
        end)
        :ok
      rescue
        error in [File.Error, RuntimeError] -> {:error, Exception.message(error)}
      end
    end)
  end

  # Una consulta: si algún centro no existe se informa y no se busca.
  # Si existen, primero se calcula el alcance con el Stream infinito; la
  # DFS exhaustiva solo se ejecuta si el destino quedó en el conjunto final.
  defp procesar_consulta(grafo, archivos, origen, destino) do
    faltantes = [origen, destino] |> Enum.uniq() |> Enum.reject(&Grafo.existe?(grafo, &1))
    if faltantes != [] do
      Reportes.desconocidos(archivos, origen, destino, faltantes)
    else
      resultado = Alcance.estabilizar(grafo, origen)
      alcanzable? = MapSet.member?(resultado.centros, destino)
      Reportes.alcance(archivos.alcance, origen, destino, resultado, alcanzable?)
      itinerarios =
        if alcanzable? do
          Rutas.buscar(grafo, origen, destino)
        else
          []
        end
      Reportes.itinerarios(archivos.itinerarios, origen, destino, itinerarios)
    end
  end
end
