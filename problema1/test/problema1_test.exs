Code.require_file("../cargar.exs", __DIR__)
ExUnit.start()

defmodule Problema1Test do
  use ExUnit.Case
  import ExUnit.CaptureIO

  defp registro(texto, linea) do
    {:ok, tramo} = Tramo.parse(texto)
    %{linea: linea, contenido: texto, tramo: tramo}
  end

  defp ejemplo do
    [registro("A,B,8,5", 2), registro("B,D,7,4", 3),
     registro("A,C,6,2", 4), registro("C,D,12,1", 5),
     registro("B,C,3,2", 6), registro("C,B,4,1", 7),
     registro("A,A,2,1", 8), registro("A,B,9,7", 9)]
  end

  defp directorio_temporal do
    dir = Path.join(System.tmp_dir!(), "rutas_test_#{System.unique_integer([:positive, :monotonic])}")
    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf!(dir) end)
    dir
  end

  test "parsea tramos válidos y rechaza campos incorrectos" do
    assert {:ok, %Tramo{origen: "A", destino: "B", minutos: 8, costo: 5}} = Tramo.parse(" A, B, 8,5 ")
    for invalida <- ["A,B,0,1", "A,B,-1,2", "A,B,3,0", "A,B,2x,3", "A,B,3", ",B,2,3", "A,B,2,3,4"] do
      assert {:error, _} = Tramo.parse(invalida)
    end
  end

  test "la depuración es dirigida, conserva primera, orden y líneas físicas" do
    {validos, descartados} = Validacion.depurar(ejemplo())
    assert Enum.map(validos, & &1.linea) == [2, 3, 4, 5, 6, 7]
    assert Enum.map(descartados, fn {r, _} -> r.linea end) == [8, 9]
    assert [{_, motivo_bucle}, {_, motivo_duplicado}] = descartados
    assert motivo_bucle =~ "bucle"
    assert motivo_duplicado =~ "duplicada"
    assert {[], []} == Validacion.depurar([])
  end

  test "ejemplo del PDF: cuatro rutas, detalle, orden DFS y mínimos" do
    {validos, _} = Validacion.depurar(ejemplo())
    grafo = Grafo.construir(validos)
    rutas = Rutas.buscar(grafo, "A", "D")
    assert Enum.map(rutas, & &1.centros) == [["A", "B", "D"], ["A", "B", "C", "D"], ["A", "C", "D"], ["A", "C", "B", "D"]]
    assert Enum.map(rutas, &{&1.minutos, &1.costo}) == [{15, 9}, {23, 8}, {18, 3}, {17, 7}]
    assert Enum.map(hd(rutas).tramos, &{&1.origen, &1.destino, &1.minutos, &1.costo}) == [{"A", "B", 8, 5}, {"B", "D", 7, 4}]
    assert Rutas.optimos(rutas) == %{tramos: [1, 3], tiempo: [1], costo: [3]}
    assert Rutas.buscar(grafo, "B", "A") == []
  end

  test "todos los empates y origen igual a destino" do
    registros = [registro("A,B,1,1", 1), registro("B,D,1,1", 2),
                 registro("A,C,1,1", 3), registro("C,D,1,1", 4)]
    grafo = Grafo.construir(registros)
    assert Rutas.optimos(Rutas.buscar(grafo, "A", "D")) == %{tramos: [1, 2], tiempo: [1, 2], costo: [1, 2]}
    assert [%Itinerario{centros: ["A"], tramos: [], minutos: 0, costo: 0}] = Rutas.buscar(grafo, "A", "A")
    assert Rutas.optimos([]) == %{tramos: [], tiempo: [], costo: []}
  end

  test "alcance acumulativo, ciclo y primer estado repetido" do
    grafo = Grafo.construir([registro("A,B,1,1", 1), registro("B,A,1,1", 2), registro("B,C,1,1", 3)])
    r = Alcance.estabilizar(grafo, "A")
    assert Enum.map(r.estados, fn {n, s} -> {n, Enum.sort(MapSet.to_list(s))} end) ==
      [{0, ["A"]}, {1, ["A", "B"]}, {2, ["A", "B", "C"]}]
    assert r.estable_en == 3
    assert length(Enum.take(Alcance.stream(grafo, "A"), 8)) == 8
    terminal = Alcance.estabilizar(grafo, "C")
    assert terminal.estable_en == 1
    assert terminal.estados == [{0, MapSet.new(["C"])}]
  end

  test "integración: líneas físicas, comentarios, parseo, desconocidos y salidas truncadas" do
    dir = directorio_temporal()
    File.write!(Path.join(dir, "tramos.csv"), "# comentario\n\nA,B,2,4\nA,A,1,1\nA,B,9,9\nB,C,no,1\n")
    File.write!(Path.join(dir, "consultas.txt"), " # comentario\n\nA,B\nB,A\nA,A\nX,A\nA,\n")
    File.write!(Path.join(dir, "itinerarios.txt"), "CONTENIDO ANTERIOR")
    capture_io(fn -> assert :ok = Aplicacion.ejecutar(dir) end)
    itinerarios = File.read!(Path.join(dir, "itinerarios.txt"))
    assert itinerarios =~ "A → B"
    assert itinerarios =~ "Sin itinerarios"
    assert itinerarios =~ "Sin tramos"
    assert itinerarios =~ "desconocido"
    assert itinerarios =~ "Línea 7: consulta inválida"
    refute itinerarios =~ "CONTENIDO ANTERIOR"
    depuracion = File.read!(Path.join(dir, "depuracion_tramos.txt"))
    assert depuracion =~ "Línea 4:"
    assert depuracion =~ "Línea 5:"
    assert File.read!(Path.join(dir, "errores_tramos.txt")) =~ "Línea 6:"
    alcance = File.read!(Path.join(dir, "alcance_centros.txt"))
    assert alcance =~ "Paso 0: {A}"
    assert alcance =~ "Estabilización: paso 2"
  end

  test "archivos vacíos y archivo requerido ausente no lanzan excepciones" do
    dir = directorio_temporal()
    File.write!(Path.join(dir, "tramos.csv"), "")
    File.write!(Path.join(dir, "consultas.txt"), "")
    assert :ok = Aplicacion.ejecutar(dir)
    assert File.read!(Path.join(dir, "itinerarios.txt")) == ""
    File.rm!(Path.join(dir, "consultas.txt"))
    assert {:error, mensaje} = Aplicacion.ejecutar(dir)
    assert mensaje =~ "consultas.txt"
    File.rm!(Path.join(dir, "tramos.csv"))
    assert {:error, mensaje} = Aplicacion.ejecutar(dir)
    assert mensaje =~ "tramos.csv"
  end
end
