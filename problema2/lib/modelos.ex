defmodule Color do
  @moduledoc """
  Un color de la paleta (una línea de paleta.csv).

    * `simbolo` - símbolo del mapa, p. ej. "A" o "." (fondo).
    * `nombre`  - nombre legible, p. ej. "agua".
    * `hex`     - color en formato #RRGGBB, p. ej. "#2563EB".
  """
  @enforce_keys [:simbolo, :nombre, :hex]
  defstruct [:simbolo, :nombre, :hex]
end

defmodule Region do
  @moduledoc """
  Región: grupo de casillas del mismo símbolo unidas por arriba, abajo,
  izquierda o derecha (las diagonales no unen). Coordenadas {fila, columna}
  desde 0.

    * `id`        - número de región (1, 2, 3...) según el orden de barrido.
    * `simbolo`   - símbolo común de sus casillas.
    * `celdas`    - lista ordenada de coordenadas {fila, columna}.
    * `area`      - cantidad de casillas.
    * `perimetro` - lados que tocan el borde del mapa u otro símbolo.
    * `fila_min`, `columna_min`, `fila_max`, `columna_max` - caja envolvente.
  """
  @enforce_keys [:id, :simbolo, :celdas, :area, :perimetro, :fila_min, :fila_max, :columna_min, :columna_max]
  defstruct [:id, :simbolo, :celdas, :area, :perimetro, :fila_min, :fila_max, :columna_min, :columna_max]
end
