defmodule GuayabitaRoll.Game.Supervisor do
  @moduledoc """
  Supervisor dinámico para los procesos de juego.
  """
  use DynamicSupervisor

  alias GuayabitaRoll.Game.Server

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Inicia una nueva sala de juego.
  """
  def start_game(game_id, min_bet \\ 1000) do
    spec = {Server, [game_id: game_id, min_bet: min_bet]}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @doc """
  Detiene una sala de juego.
  """
  def stop_game(game_id) do
    case Registry.lookup(GuayabitaRoll.Game.Registry, game_id) do
      [{pid, _}] -> DynamicSupervisor.terminate_child(__MODULE__, pid)
      [] -> {:error, :not_found}
    end
  end
end
