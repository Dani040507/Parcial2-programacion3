defmodule Salidas do
  @moduledoc """
  Contenido de las salidas del Problema 2: regiones.csv, resumen y SVG.

  Ninguna función escribe en disco: cada una devuelve un Stream de
  fragmentos (líneas o etiquetas). EntradaSalida.escribir_fragmentos/3
  los escribe uno por uno, así nunca se arma el documento completo en
  memoria (requisito general 4).
  """

  @doc """
  Stream de líneas de regiones.csv: cabecera y una línea por región con
  `id;simbolo;area;perimetro;desde;hasta`.
  """
  def csv(regiones) do
    cabecera = ["id;simbolo;area;perimetro;desde;hasta\n"]
    lineas = Stream.map(regiones, fn r ->
      desde = "{#{r.fila_min},#{r.columna_min}}"
      hasta = "{#{r.fila_max},#{r.columna_max}}"
      [r.id, r.simbolo, r.area, r.perimetro, desde, hasta]
      |> Enum.map(&campo_csv/1) |> Enum.join(";") |> Kernel.<>("\n")
    end)
    # Stream.concat une la cabecera con las líneas sin calcularlas todavía.
    Stream.concat(cabecera, lineas)
  end

  # Si un campo contiene ; comillas o saltos de línea, se entrecomilla y
  # se duplican las comillas internas (regla estándar de CSV).
  defp campo_csv(valor) do
    valor = to_string(valor)
    if String.contains?(valor, [";", "\"", "\n", "\r"]) do
      "\"" <> String.replace(valor, "\"", "\"\"") <> "\""
    else
      valor
    end
  end

  @doc """
  Stream de líneas de resumen_regiones.txt: dimensiones, número de
  regiones, detalle y máximos de área y perímetro (con empates).
  El mismo Stream se muestra en pantalla.
  """
  def resumen(regiones, filas) do
    {max_area, max_perimetro} = Regiones.extremos(regiones)
    columnas = case filas do [primera | _] -> length(primera); [] -> 0 end
    detalle = Stream.map(regiones, fn r ->
      "  ##{r.id} #{r.simbolo}: área=#{r.area}, perímetro=#{r.perimetro}, caja=(#{r.fila_min},#{r.columna_min})..(#{r.fila_max},#{r.columna_max})\n"
    end)
    Stream.concat([
      ["Mapa: #{length(filas)} filas x #{columnas} columnas\n", "Regiones: #{length(regiones)}\n"],
      detalle,
      ["Área máxima: #{extremo(max_area, :area)}\n", "Perímetro máximo: #{extremo(max_perimetro, :perimetro)}\n"]
    ])
  end

  # Texto de un máximo: "5 (IDs: 3)" o "sin regiones".
  defp extremo([], _campo), do: "sin regiones"
  defp extremo(regiones, campo) do
    ids = regiones |> Enum.map(&to_string(&1.id)) |> Enum.join(", ")
    "#{Map.fetch!(hd(regiones), campo)} (IDs: #{ids})"
  end

  @doc """
  Stream de fragmentos del SVG, en este orden:
    1. apertura: declaración XML y etiqueta <svg> de 40*columnas x 40*filas;
    2. un <rect> de 40x40 por casilla, con el color de la paleta (incluido
       el fondo) y borde visible;
    3. líneas gruesas en los lados donde termina cada región;
    4. un <text> con el ID en la primera casilla de cada región;
    5. cierre </svg>.
  Todo texto que entra al XML pasa por xml/1 para escaparlo.
  """
  def svg_fragmentos(filas, colores, regiones) do
    ancho = length(hd(filas)) * 40
    alto = length(filas) * 40
    inicio = ["<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n",
      "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"#{ancho}\" height=\"#{alto}\" viewBox=\"0 0 #{ancho} #{alto}\">\n"]
    # Casilla (fila r, columna c) -> rectángulo en x = c*40, y = r*40.
    celdas = filas |> Stream.with_index() |> Stream.flat_map(fn {fila, r} ->
      fila |> Stream.with_index() |> Stream.map(fn {s, c} ->
        color = Map.fetch!(colores, s)
        "<rect x=\"#{c * 40}\" y=\"#{r * 40}\" width=\"40\" height=\"40\" fill=\"#{xml(color.hex)}\" stroke=\"#b0b0b0\" stroke-width=\"0.5\"><title>#{xml(s)}: #{xml(color.nombre)}</title></rect>\n"
      end)
    end)
    bordes = regiones |> Stream.flat_map(fn region ->
      conjunto = MapSet.new(region.celdas)
      Stream.flat_map(region.celdas, fn {r, c} -> bordes_celda(r, c, conjunto) end)
    end)
    # Las celdas están ordenadas, así que la primera es la de menor fila/columna.
    etiquetas = Stream.map(regiones, fn region ->
      [{r, c} | _] = region.celdas
      "<text x=\"#{c * 40 + 20}\" y=\"#{r * 40 + 25}\" text-anchor=\"middle\" font-family=\"sans-serif\" font-size=\"15\" font-weight=\"bold\" fill=\"#000\" stroke=\"#fff\" stroke-width=\"3\" paint-order=\"stroke\">#{region.id}</text>\n"
    end)
    Stream.concat([inicio, celdas, bordes, etiquetas, ["</svg>\n"]])
  end

  # Para una casilla, dibuja una línea en cada lado cuyo vecino NO es de la
  # misma región (borde exterior de la región).
  defp bordes_celda(r, c, conjunto) do
    x = c * 40
    y = r * 40
    lados = [{{r - 1, c}, {x, y, x + 40, y}}, {{r + 1, c}, {x, y + 40, x + 40, y + 40}},
      {{r, c - 1}, {x, y, x, y + 40}}, {{r, c + 1}, {x + 40, y, x + 40, y + 40}}]
    for {vecino, {x1, y1, x2, y2}} <- lados, not MapSet.member?(conjunto, vecino) do
      "<line x1=\"#{x1}\" y1=\"#{y1}\" x2=\"#{x2}\" y2=\"#{y2}\" stroke=\"#111\" stroke-width=\"2\"/>\n"
    end
  end

  # Escapa texto para XML: quita caracteres de control no permitidos y
  # reemplaza & < > " ' por sus entidades. El & va primero para no
  # escapar dos veces.
  defp xml(texto) do
    texto |> String.replace(~r/[\x00-\x08\x0B\x0C\x0E-\x1F\x{FFFE}\x{FFFF}]/u, "")
    |> String.replace("&", "&amp;") |> String.replace("<", "&lt;") |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;") |> String.replace("'", "&apos;")
  end
end
