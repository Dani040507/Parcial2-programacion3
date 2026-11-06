ExUnit.start()
raiz = Path.expand("..", __DIR__)
for archivo <- ["modelos", "validacion", "regiones", "salidas", "entrada_salida", "aplicacion"] do
  Code.require_file("lib/#{archivo}.ex", raiz)
end

defmodule Problema2Test do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  defp temporal do
    ruta = Path.join(System.tmp_dir!(), "problema2_test_#{System.unique_integer([:positive, :monotonic])}")
    File.mkdir_p!(ruta)
    on_exit(fn -> File.rm_rf!(ruta) end)
    ruta
  end
  # Las salidas son Streams de fragmentos; se juntan solo para comparar en la prueba.
  defp texto(fragmentos), do: fragmentos |> Enum.to_list() |> IO.iodata_to_binary()
  defp colores do
    {colores, []} = Validacion.paleta([
      {[".", "fondo", "#F1F5F9"], 1}, {["A", "agua", "#2563EB"], 2},
      {["B", "bosque", "#16A34A"], 3}, {["C", "cultivo", "#F59E0B"], 4}])
    colores
  end
  defp matrices_maximos do
    a = List.duplicate("A", 3)
    c = List.duplicate("C", 3)
    [a ++ ["."] ++ List.duplicate("B", 8) ++ ["."] ++ c ++ ["."] ++ List.duplicate("D", 8),
     a ++ List.duplicate(".", 10) ++ c ++ List.duplicate(".", 9),
     a ++ List.duplicate(".", 10) ++ c ++ List.duplicate(".", 9)]
  end
  test "archivos físicos del ejemplo 5x5 y regiones exactas" do
    root = Path.expand("..", __DIR__)
    assert File.read!(Path.join(root, "mapa.txt")) == "A A . B B\nA . . B .\n. . C . .\nC C C . B\nC . . B B\n"
    assert File.read!(Path.join(root, "paleta.csv")) == "A,agua,#2563EB\nB,bosque,#16A34A\nC,cultivo,#F59E0B\n.,fondo,#F1F5F9\n"
    {:ok, lp} = EntradaSalida.leer(Path.join(root, "paleta.csv"), :paleta)
    {colores, []} = Validacion.paleta(lp)
    {:ok, lm} = EntradaSalida.leer(Path.join(root, "mapa.txt"), :mapa)
    {filas, []} = Validacion.mapa(lm, colores)
    assert length(filas) == 5 and Enum.all?(filas, &(length(&1) == 5))
    rs = Regiones.encontrar(filas)
    assert Enum.map(rs, &{&1.id, &1.simbolo, &1.area, &1.perimetro}) == [{1,"A",3,8},{2,"B",3,8},{3,"C",5,12},{4,"B",3,8}]
    assert Enum.at(rs, 2).celdas == [{2,2},{3,0},{3,1},{3,2},{4,0}]
    assert Enum.map(rs, &{&1.fila_min,&1.columna_min,&1.fila_max,&1.columna_max}) == [{0,0,1,1},{0,3,1,4},{2,0,4,2},{3,3,4,4}]
    assert texto(Salidas.csv(rs)) == "id;simbolo;area;perimetro;desde;hasta\n1;A;3;8;{0,0};{1,1}\n2;B;3;8;{0,3};{1,4}\n3;C;5;12;{2,0};{4,2}\n4;B;3;8;{3,3};{4,4}\n"
  end
  test "máximos diferentes y TODOS sus empates" do
    filas = matrices_maximos()
    assert Enum.all?(filas, &(length(&1) == 25))
    rs = Regiones.encontrar(filas)
    assert Enum.map(rs, &{&1.id,&1.simbolo,&1.area,&1.perimetro}) == [{1,"A",9,12},{2,"B",8,18},{3,"C",9,12},{4,"D",8,18}]
    {areas, perimetros} = Regiones.extremos(rs)
    assert Enum.map(areas, & &1.id) == [1, 3]
    assert Enum.map(perimetros, & &1.id) == [2, 4]
    texto = texto(Salidas.resumen(rs, filas))
    assert texto =~ "Área máxima: 9 (IDs: 1, 3)"
    assert texto =~ "Perímetro máximo: 18 (IDs: 2, 4)"
    refute texto =~ "Área mínima"
  end
  test "fondo, borde, diagonal, rectángulo y hueco interior" do
    assert [%Region{area: 1, perimetro: 4, celdas: [{0,0}]}] = Regiones.encontrar([["A"]])
    assert Regiones.encontrar([["."]]) == []
    assert Regiones.extremos([]) == {[], []}
    resumen = texto(Salidas.resumen([], [["."]]))
    assert resumen =~ "Área máxima: sin regiones" and resumen =~ "Perímetro máximo: sin regiones"
    assert length(Regiones.encontrar([["A", "."], [".", "A"]])) == 2
    assert [%Region{area: 6, perimetro: 10}] = Regiones.encontrar([["A","A","A"],["A","A","A"]])
    assert [%Region{area: 8, perimetro: 16}] = Regiones.encontrar([["A","A","A"],["A",".","A"],["A","A","A"]])
  end
  test "entrada parseada con líneas físicas, comentarios y UTF-8 inválido" do
    d = temporal()
    map = Path.join(d, "mapa")
    pal = Path.join(d, "paleta")
    File.write!(map, ["# comentario\n\n A   . \n # otro\nA Z\n", <<255>>, "\n"])
    File.write!(pal, ["# comentario\n\n A , agua , #2563EB \n", <<255>>, "\n.,fondo,#F1F5F9\n"])
    assert {:ok, [{["A","."],3},{["A","Z"],5},{:utf8_invalido,6}]} = EntradaSalida.leer(map, :mapa)
    assert {:ok, [{["A","agua","#2563EB"],3},{:utf8_invalido,4},{[".","fondo","#F1F5F9"],5}]} = EntradaSalida.leer(pal, :paleta)
    {:ok, mp} = EntradaSalida.leer(map, :mapa)
    {_filas, es} = Validacion.mapa(mp, colores())
    assert Enum.any?(es, &String.contains?(&1, "línea 5, fila 1, columna 1"))
    assert Enum.any?(es, &String.contains?(&1, "línea 6, fila 2: UTF-8 inválido"))
    {:ok, pp} = EntradaSalida.leer(pal, :paleta)
    {_colores, es} = Validacion.paleta(pp)
    assert Enum.any?(es, &String.contains?(&1, "línea 4: UTF-8 inválido"))
  end
  test "validación recursiva acumula errores distintos y múltiples por línea" do
    {colores, ep} = Validacion.paleta([
      {["A","","#ZZZZZZ"],3}, {["A","otro","#123456"],6}, {["B","","#123"],8},
      {["pocos","campos"],10}, {:utf8_invalido,11}])
    for fragmento <- ["línea 3: nombre vacío", "línea 3: color", "línea 6: símbolo", "duplicado", "línea 8: nombre vacío", "línea 8: color", "línea 10", "línea 11: UTF-8 inválido", "fondo"] do
      assert Enum.any?(ep, &String.contains?(&1, fragmento)), fragmento
    end
    {_f, em} = Validacion.mapa([{["A","Z"],4},{["A"],7},{:utf8_invalido,9}], colores)
    for fragmento <- ["línea 4, fila 0, columna 1", "línea 7, fila 1: 1 columnas", "línea 9, fila 2: UTF-8 inválido"] do
      assert Enum.any?(em, &String.contains?(&1, fragmento)), fragmento
    end
    assert elem(Validacion.paleta([]),1) != [] and elem(Validacion.mapa([], %{}),1) != []
  end
  test "CSV escapa símbolo con delimitador y comillas" do
    rs = Regiones.encontrar([["x;\"y"]])
    assert texto(Salidas.csv(rs)) == "id;simbolo;area;perimetro;desde;hasta\n1;\"x;\"\"y\";1;4;{0,0};{0,0}\n"
  end
  test "SVG es XML válido, escapa valores y dibuja bordes" do
    cs = Map.put(colores(), "A", %Color{simbolo: "A", nombre: "uno; <dos> & \"tres\" 'cuatro'", hex: "#FF0000"})
    filas = [["A", "."]]
    svg = filas |> Salidas.svg_fragmentos(cs, Regiones.encontrar(filas)) |> Enum.to_list() |> IO.iodata_to_binary()
    assert svg =~ "&lt;dos&gt; &amp; &quot;tres&quot; &apos;cuatro&apos;"
    assert svg =~ "width=\"80\"" and svg =~ ">1</text>"
    assert length(Regex.scan(~r/<line /, svg)) == 4
    {xml, resto} = :xmerl_scan.string(String.to_charlist(svg), quiet: true)
    assert elem(xml, 0) == :xmlElement
    assert resto == [] or String.trim(to_string(resto)) == ""
  end
  test "aplicación genera archivos, pantalla idéntica y limpia resultados obsoletos" do
    d = temporal(); map = Path.join(d,"mapa"); pal = Path.join(d,"paleta"); out = Path.join(d,"out")
    File.write!(map,"A .\n"); File.write!(pal,".,fondo,#FFFFFF\nA,agua,#FF0000\n")
    pantalla = capture_io(fn -> assert Aplicacion.ejecutar(map,pal,out) == 0 end)
    assert pantalla == File.read!(Path.join(out,"resumen_regiones.txt"))
    for file <- ["validacion_mapa.txt","regiones.csv","mapa_regiones.svg","resumen_regiones.txt"], do: assert(File.exists?(Path.join(out,file)))
    File.write!(map,"Z\n")
    capture_io(:stderr, fn -> assert Aplicacion.ejecutar(map,pal,out) == 1 end)
    assert File.read!(Path.join(out,"validacion_mapa.txt")) =~ "sin color"
    for file <- ["regiones.csv","mapa_regiones.svg","resumen_regiones.txt"], do: refute(File.exists?(Path.join(out,file)))
  end
  test "archivos faltantes se informan sin excepción" do
    d = temporal(); out = Path.join(d,"out")
    error = capture_io(:stderr, fn -> assert Aplicacion.ejecutar(Path.join(d,"no_mapa"),Path.join(d,"no_paleta"),out) == 1 end)
    log = File.read!(Path.join(out,"validacion_mapa.txt"))
    assert error =~ "Validación fallida" and log =~ "no_mapa" and log =~ "no_paleta"
    refute File.exists?(Path.join(out,"mapa_regiones.svg"))
  end
  test "proteger entrada de coincidencia exacta con salida" do
    d=temporal(); input=Path.join(d,"regiones.csv"); File.write!(input,"contenido")
    capture_io(:stderr, fn -> assert Aplicacion.ejecutar(input,Path.join(d,"paleta"),d) == 1 end)
    assert File.read!(input) == "contenido"
  end
end
