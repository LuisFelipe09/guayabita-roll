defmodule GuayabitaRoll.Game.ServerTest do
  use ExUnit.Case
  alias GuayabitaRoll.Game.{Server, Supervisor}

  setup do
    # Start the Registry and Supervisor manually if not started by app
    # (Since we are running unit tests, Application might be started or not depending on runner)
    # However, in normal mix test, the app is started.
    # We'll use random game IDs to avoid collision.
    game_id = "game-#{:rand.uniform(10000)}"
    {:ok, game_id: game_id}
  end

  test "starts a game process", %{game_id: game_id} do
    {:ok, pid} = Supervisor.start_game(game_id)
    assert Process.alive?(pid)

    state = Server.get_state(game_id)
    assert state.id == game_id
    assert state.pot == 0
  end

  test "manages players via GenServer calls", %{game_id: game_id} do
    {:ok, _pid} = Supervisor.start_game(game_id)

    :ok = Server.add_player(game_id, "p1", "Alice", 1000)
    state = Server.get_state(game_id)

    assert map_size(state.players) == 1
    assert state.players["p1"].name == "Alice"
  end

  test "process isolation: crash does not affect other games" do
    game1 = "crash-test-1"
    game2 = "crash-test-2"

    {:ok, pid1} = Supervisor.start_game(game1)
    {:ok, _pid2} = Supervisor.start_game(game2)

    :ok = Server.add_player(game1, "p1", "Alice", 1000)
    :ok = Server.add_player(game2, "p2", "Bob", 1000)

    # Force crash game1
    Process.exit(pid1, :kill)

    # Verify game1 is gone (or restarted with empty state if we handled restart differently,
    # but :transient means it restarts only if abnormal exit? No, :transient restarts if exit reason != :normal.
    # :kill is abnormal. So it should restart empty.)

    # Wait a bit for restart
    :timer.sleep(50)

    # Verify game2 is still happy
    state2 = Server.get_state(game2)
    assert state2.players["p2"].name == "Bob"

    # Verify game1 restarted (new pid, empty state)
    [{new_pid1, _}] = Registry.lookup(GuayabitaRoll.Game.Registry, game1)
    assert new_pid1 != pid1

    state1 = Server.get_state(game1)
    # Since it restarted, state is fresh (empty players)
    assert map_size(state1.players) == 0
  end
end
