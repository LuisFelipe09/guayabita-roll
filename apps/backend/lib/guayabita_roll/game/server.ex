defmodule GuayabitaRoll.Game.Server do
  @moduledoc """
  GenServer que gestiona el estado de una partida individual.
  Cada sala de juego corre en su propio proceso aislado.
  """
  use GenServer, restart: :transient

  require Logger
  alias GuayabitaRoll.Game.{Engine, State}

  # Timeout de inactividad (30 minutos)
  @timeout :timer.minutes(30)
  # Timeout para decisiones del usuario (45 segundos) - Ajustable
  @turn_timeout 45_000

  # --- Client API ---

  @doc """
  Inicia un servidor de juego.
  """
  def start_link(opts) do
    game_id = Keyword.fetch!(opts, :game_id)
    min_bet = Keyword.get(opts, :min_bet, 1000)

    GenServer.start_link(__MODULE__, {game_id, min_bet}, name: via_tuple(game_id))
  end

  def add_player(game_id, player_id, name, balance) do
    GenServer.call(via_tuple(game_id), {:add_player, player_id, name, balance})
  end

  def remove_player(game_id, player_id) do
    GenServer.call(via_tuple(game_id), {:remove_player, player_id})
  end

  def start_round(game_id) do
    GenServer.call(via_tuple(game_id), :start_round)
  end

  def roll_dice(game_id, player_id, client_seed, server_seed) do
    GenServer.call(via_tuple(game_id), {:roll_dice, player_id, client_seed, server_seed})
  end

  def place_bet(game_id, player_id, amount) do
    GenServer.call(via_tuple(game_id), {:place_bet, player_id, amount})
  end

  def skip_bet(game_id, player_id) do
    GenServer.call(via_tuple(game_id), {:skip_bet, player_id})
  end

  def get_state(game_id) do
    GenServer.call(via_tuple(game_id), :get_state)
  end

  # --- Server Callbacks ---

  @impl true
  def init({game_id, min_bet}) do
    # Inicializar estado con el Engine
    state = Engine.new_game(game_id, min_bet)
    Logger.info("Game #{game_id} started with min_bet #{min_bet}")
    {:ok, state, @timeout}
  end

  @impl true
  def handle_call({:add_player, pid, name, bal}, _from, state) do
    case Engine.add_player(state, pid, name, bal) do
      {:ok, new_state} ->
        notify_update(new_state)
        {:reply, :ok, new_state, @timeout}
      error ->
        {:reply, error, state, @timeout}
    end
  end

  @impl true
  def handle_call({:remove_player, pid}, _from, state) do
    case Engine.remove_player(state, pid) do
      {:ok, new_state} ->
        notify_update(new_state)
        # Si no quedan jugadores, podríamos detener el proceso
        if map_size(new_state.players) == 0 do
           {:stop, :normal, :ok, new_state}
        else
           {:reply, :ok, new_state, @timeout}
        end
      error ->
        {:reply, error, state, @timeout}
    end
  end

  @impl true
  def handle_call(:start_round, _from, state) do
    case Engine.start_round(state) do
      {:ok, new_state} ->
        notify_update(new_state)
        schedule_turn_timeout()
        {:reply, :ok, new_state, @timeout}
      error ->
        {:reply, error, state, @timeout}
    end
  end

  @impl true
  def handle_call({:roll_dice, pid, c_seed, s_seed}, _from, state) do
    case Engine.roll_dice(state, pid, c_seed, s_seed) do
      {:ok, new_state} ->
        notify_update(new_state)
        reset_turn_timeout()
        {:reply, {:ok, new_state.last_event}, new_state, @timeout}
      error ->
        {:reply, error, state, @timeout}
    end
  end

  @impl true
  def handle_call({:place_bet, pid, amt}, _from, state) do
    case Engine.place_bet(state, pid, amt) do
      {:ok, new_state} ->
        notify_update(new_state)
        reset_turn_timeout()
        {:reply, :ok, new_state, @timeout}
      error ->
        {:reply, error, state, @timeout}
    end
  end

  @impl true
  def handle_call({:skip_bet, pid}, _from, state) do
    case Engine.skip_bet(state, pid) do
      {:ok, new_state} ->
        notify_update(new_state)
        reset_turn_timeout()
        {:reply, :ok, new_state, @timeout}
      error ->
        {:reply, error, state, @timeout}
    end
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state, @timeout}
  end

  @impl true
  def handle_info(:turn_timeout, state) do
    Logger.info("Turn timeout for Game #{state.id}")
    case Engine.handle_timeout(state) do
      {:ok, new_state} ->
        notify_update(new_state)
        reset_turn_timeout()
        {:noreply, new_state, @timeout}
      _ ->
        {:noreply, state, @timeout}
    end
  end

  @impl true
  def handle_info(:timeout, state) do
    Logger.info("Stopping Game #{state.id} due to inactivity")
    {:stop, :normal, state}
  end

  # --- Helpers ---

  defp via_tuple(game_id) do
    {:via, Registry, {GuayabitaRoll.Game.Registry, game_id}}
  end

  defp notify_update(state) do
    # Aquí emitiríamos el evento por Phoenix PubSub
    # Phoenix.PubSub.broadcast(GuayabitaRoll.PubSub, "game:#{state.id}", {:game_update, state})
    # Por ahora solo log
    Logger.debug("Game Update: Phase #{state.phase} | Pot #{state.pot}")
  end

  # Timer para el timeout de turno
  defp schedule_turn_timeout do
     # En una implementación real, cancelaríamos el timer anterior si existe
     # guardando la referencia en el estado.
     # Por simplicidad en este paso, usaremos Process.send_after simple,
     # pero ojo: esto puede acumular mensajes si no se cancela.
     # TODO: Implementar gestión de timers correcta (cancelar anterior).
     Process.send_after(self(), :turn_timeout, @turn_timeout)
  end

  defp reset_turn_timeout do
     schedule_turn_timeout()
  end
end
