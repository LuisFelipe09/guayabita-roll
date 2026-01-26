defmodule GuayabitaRoll.Game.Player do
  @moduledoc """
  Representa a un jugador en una mesa de juego.
  """
  @derive Jason.Encoder
  defstruct [
    :id,
    :name,
    :balance,      # Saldo actual del jugador en la mesa (MCOP)
    :status        # :active, :folded, :eliminated
  ]

  @type t :: %__MODULE__{
    id: String.t(),
    name: String.t(),
    balance: integer(),
    status: atom()
  }

  def new(id, name, balance) do
    %__MODULE__{
      id: id,
      name: name,
      balance: balance,
      status: :active
    }
  end
end
