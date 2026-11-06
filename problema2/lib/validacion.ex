defmodule Validacion do
  @moduledoc """
  Validación previa con recursión: mapa y paleta (Problema 2).

  Recibe pares `{campos, línea_física}` (o `{:utf8_invalido, línea}`)
  producidos por EntradaSalida.leer/2 y los recorre con recursión propia.
  Regla del parcial: aquí NO se usa Enum ni Stream; hasta contar o invertir
  listas se hace con funciones recursivas propias.

  Se reportan TODOS los errores (no solo el primero), cada uno con su
  línea, fila o columna. Mientras haya errores no se calculan regiones.
  """

  @doc """
  Valida paleta.csv. Revisa: tres campos, símbolo no vacío, nombre no
  vacío, color #RRGGBB, símbolos repetidos y que exista el fondo ".".
  Devuelve `{mapa_de_colores, errores}`.
  """
  def paleta(lineas) do
    {colores, _vistos, errores} = paleta_rec(lineas, %{}, %{}, [])
    errores = if Map.has_key?(colores, "."), do: errores,
      else: ["paleta.csv: falta una definición válida para el fondo '.'" | errores]
    {colores, invertir(errores)}
  end

  # paleta_rec/4 acumula:
  #   colores - mapa símbolo => %Color{} con las líneas correctas
  #   vistos  - mapa símbolo => primera línea donde apareció (duplicados)
  #   errores - lista de mensajes (al revés)
  # Caso base: no quedan líneas.
  defp paleta_rec([], colores, vistos, errores), do: {colores, vistos, errores}

  # Línea con bytes que no son UTF-8 válido.
  defp paleta_rec([{:utf8_invalido, num} | resto], colores, vistos, errores) do
    paleta_rec(resto, colores, vistos, ["paleta.csv línea #{num}: UTF-8 inválido" | errores])
  end

  # Línea con exactamente tres campos: se revisa cada regla y se acumulan
  # todos los errores de la línea.
  defp paleta_rec([{[s, nombre, hex], num} | resto], colores, vistos, errores) do
    previo = Map.get(vistos, s)
    simbolo_valido = s != "" and not Regex.match?(~r/\s/u, s) and not String.starts_with?(s, "#")
    # # seguido de exactamente 6 dígitos hexadecimales.
    hex_valido = Regex.match?(~r/^#[0-9a-fA-F]{6}$/, hex)
    errores = if simbolo_valido, do: errores,
      else: ["paleta.csv línea #{num}: símbolo vacío, con espacios o reservado '#'" | errores]
    errores = if nombre != "", do: errores, else: ["paleta.csv línea #{num}: nombre vacío" | errores]
    errores = if hex_valido, do: errores,
      else: ["paleta.csv línea #{num}: color #{inspect(hex)} no tiene formato #RRGGBB" | errores]
    errores = if previo == nil, do: errores,
      else: ["paleta.csv línea #{num}: símbolo #{inspect(s)} duplicado (primera línea #{previo})" | errores]
    # Solo se guarda el color si la línea es totalmente correcta y es la primera vez.
    colores = if simbolo_valido and nombre != "" and hex_valido and not Map.has_key?(colores, s),
      do: Map.put(colores, s, %Color{simbolo: s, nombre: nombre, hex: hex}), else: colores
    vistos = if s == "", do: vistos, else: Map.put_new(vistos, s, num)
    paleta_rec(resto, colores, vistos, errores)
  end

  # Cualquier otra cantidad de campos.
  defp paleta_rec([{_campos, num} | resto], colores, vistos, errores) do
    paleta_rec(resto, colores, vistos,
      ["paleta.csv línea #{num}: se esperan tres campos separados por comas" | errores])
  end

  @doc """
  Valida mapa.txt: que haya filas, que todas tengan la misma longitud y que
  cada símbolo tenga color en la paleta. Devuelve `{filas, errores}`.
  """
  def mapa(lineas, colores) do
    {filas, _ancho, _fila, errores} = mapa_rec(lineas, colores, [], nil, 0, [])
    errores = if filas == [], do: ["mapa.txt: no contiene filas de datos" | errores], else: errores
    {invertir(filas), invertir(errores)}
  end

  # mapa_rec/6 acumula las filas, el ancho esperado (el de la primera fila),
  # el número de fila actual (desde 0) y los errores.
  defp mapa_rec([], _colores, filas, ancho, fila, errores), do: {filas, ancho, fila, errores}
  defp mapa_rec([{:utf8_invalido, num} | resto], colores, filas, ancho, fila, errores) do
    mapa_rec(resto, colores, filas, ancho, fila + 1,
      ["mapa.txt línea #{num}, fila #{fila}: UTF-8 inválido" | errores])
  end
  defp mapa_rec([{celdas, num} | resto], colores, filas, ancho, fila, errores) when is_list(celdas) do
    n = longitud(celdas, 0)
    if n == 0 do
      # Fila sin celdas: no se cuenta como fila del mapa.
      mapa_rec(resto, colores, filas, ancho, fila, errores)
    else
      # La primera fila fija el ancho; las demás deben coincidir.
      esperado = if ancho == nil, do: n, else: ancho
      errores = if n == esperado, do: errores,
        else: ["mapa.txt línea #{num}, fila #{fila}: #{n} columnas; se esperaban #{esperado}" | errores]
      errores = comprobar_celdas(celdas, colores, num, fila, 0, errores)
      mapa_rec(resto, colores, [celdas | filas], esperado, fila + 1, errores)
    end
  end

  # Revisa recursivamente, columna por columna, que cada símbolo exista en la
  # paleta. Si la paleta no se pudo leer (:sin_paleta) no se repite el error.
  defp comprobar_celdas([], _colores, _num, _fila, _col, errores), do: errores
  defp comprobar_celdas([s | resto], colores, num, fila, col, errores) do
    errores = if colores == :sin_paleta or Map.has_key?(colores, s), do: errores,
      else: ["mapa.txt línea #{num}, fila #{fila}, columna #{col}: símbolo #{inspect(s)} sin color válido" | errores]
    comprobar_celdas(resto, colores, num, fila, col + 1, errores)
  end

  # Longitud de una lista, recursiva (en lugar de length/Enum.count).
  defp longitud([], n), do: n
  defp longitud([_ | xs], n), do: longitud(xs, n + 1)

  # Inversión recursiva de una lista (en lugar de Enum.reverse).
  defp invertir(xs), do: invertir(xs, [])
  defp invertir([], acc), do: acc
  defp invertir([x | xs], acc), do: invertir(xs, [x | acc])
end
