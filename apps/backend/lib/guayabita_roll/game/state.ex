defmodule GuayabitaRoll.Game.State do
  @moduledoc """
  Estructura inmutable que mantiene el estado completo de una partida.
  """
  @derive Jason.Encoder
  defstruct [
    :id,
    :pot,                # Pote acumulado (MCOP)
    :min_bet,            # Apuesta mínima (MCOP)
    :players,            # Mapa %{player_id => %Player{}}
    :turn_order,         # Lista de player_ids en orden
    :current_turn,       # player_id del turno actual
    :phase,              # :waiting_start, :rolling_1, :deciding, :rolling_2, :finished
    :current_roll_val,   # Valor del primer lanzamiento (1-6)
    :pending_bet,        # Monto en juego para el segundo lanzamiento
    :last_event,         # Descripción del último evento para UI
    :winner_id,          # ID del ganador (si el juego terminó)
    :created_at,
    :updated_at
  ]

  @type phase :: :waiting_start | :rolling_1 | :deciding | :rolling_2 | :finished

  @type t :: %__MODULE__{
    id: String.t(),
    pot: integer(),
    min_bet: integer(),
    players: map(),
    turn_order: [String.t()],
    current_turn: String.t() | nil,
    phase: phase(),
    current_roll_val: integer() | nil,
    pending_bet: integer() | nil,
    last_event: map() | nil,
    winner_id: String.t() | nil,
    created_at: DateTime.t(),
    updated_at: DateTime.t()
  }

  def new(id, min_bet) do
    %__MODULE__{
      id: id,
      pot: 0,
      min_bet: min_bet,
      players: %{},
      turn_order: [],
      current_turn: nil,
      phase: :waiting_start,
      created_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }
  end
end
