defmodule GuayabitaRoll.Game.EngineTest do
  use ExUnit.Case
  alias GuayabitaRoll.Game.Engine

  # Semillas pre-calculadas para resultados deterministas
  # hash(server_seed <> client_seed) % 6 + 1
  @seeds %{
    1 => {"10", "server_seed"},
    2 => {"5", "server_seed"},
    3 => {"3", "server_seed"},
    4 => {"2", "server_seed"},
    5 => {"1", "server_seed"},
    6 => {"4", "server_seed"}
  }

  setup do
    state = Engine.new_game("game-123", 100) # Min bet 100
    {:ok, state: state}
  end

  test "new game initialization", %{state: state} do
    assert state.id == "game-123"
    assert state.min_bet == 100
    assert state.phase == :waiting_start
    assert state.pot == 0
  end

  test "add players", %{state: state} do
    {:ok, state} = Engine.add_player(state, "p1", "Alice", 1000)
    {:ok, state} = Engine.add_player(state, "p2", "Bob", 1000)

    assert map_size(state.players) == 2
    assert state.players["p1"].balance == 1000
    assert state.turn_order == ["p1", "p2"]
  end

  test "start round collects ante", %{state: state} do
    {:ok, state} = Engine.add_player(state, "p1", "Alice", 1000)
    {:ok, state} = Engine.add_player(state, "p2", "Bob", 1000)

    {:ok, state} = Engine.start_round(state)

    assert state.pot == 200 # 100 * 2
    assert state.players["p1"].balance == 900
    assert state.players["p2"].balance == 900
    assert state.phase == :rolling_1
    assert state.current_turn == "p1"
  end

  describe "Roll 1 Logic" do
    setup %{state: state} do
      {:ok, state} = Engine.add_player(state, "p1", "Alice", 1000)
      {:ok, state} = Engine.start_round(state)
      {:ok, state: state}
    end

    test "Roll 1: Result 1 (Sale) - Lose Turn", %{state: state} do
      {c, s} = @seeds[1]
      # Only 1 player, so turn loops back to p1?
      {:ok, state} = Engine.roll_dice(state, "p1", c, s)

      # Since we only added p1 in this setup block, logic says next turn is p1 (circular).
      # But we verify it doesn't crash.
      assert state.current_turn == "p1"
    end
  end

  # Helper setup for 2 players
  defp start_2_players(_) do
    state = Engine.new_game("game-123", 100)
    {:ok, state} = Engine.add_player(state, "p1", "Alice", 1000)
    {:ok, state} = Engine.add_player(state, "p2", "Bob", 1000)
    {:ok, state} = Engine.start_round(state)
    {:ok, state: state}
  end

  describe "Game Flow 2 Players" do
    setup :start_2_players

    test "Roll 1: Result 1 (Sale) - Turn passes", %{state: state} do
      # P1 turn
      assert state.current_turn == "p1"
      {c, s} = @seeds[1]

      {:ok, state} = Engine.roll_dice(state, "p1", c, s)

      # Turn should change to p2
      assert state.current_turn == "p2"
      assert state.players["p1"].balance == 900 # Paid ante only
      assert state.pot == 200
    end

    test "Roll 1: Result 6 (Sale) - Turn passes", %{state: state} do
      {c, s} = @seeds[6]
      {:ok, state} = Engine.roll_dice(state, "p1", c, s)

      assert state.current_turn == "p2"
    end

    test "Roll 1: Result 2 (Pone) - Pay to pot and pass", %{state: state} do
      {c, s} = @seeds[2]
      {:ok, state} = Engine.roll_dice(state, "p1", c, s)

      assert state.current_turn == "p2"
      assert state.players["p1"].balance == 800 # 900 - 100
      assert state.pot == 300 # 200 + 100
    end

    test "Roll 1: Result 5 (Pone) - Pay to pot and pass", %{state: state} do
      {c, s} = @seeds[5]
      {:ok, state} = Engine.roll_dice(state, "p1", c, s)

      assert state.current_turn == "p2"
      assert state.players["p1"].balance == 800
      assert state.pot == 300
    end

    test "Roll 1: Result 3 (Apuesta) - Enter Decision Phase", %{state: state} do
      {c, s} = @seeds[3]
      {:ok, state} = Engine.roll_dice(state, "p1", c, s)

      assert state.current_turn == "p1" # Turn stays with p1
      assert state.phase == :deciding
      assert state.current_roll_val == 3
    end

    test "Decision: Skip Bet - Lose Turn", %{state: state} do
      {c, s} = @seeds[3]
      {:ok, state} = Engine.roll_dice(state, "p1", c, s)

      {:ok, state} = Engine.skip_bet(state, "p1")

      assert state.current_turn == "p2"
      assert state.phase == :rolling_1
    end

    test "Decision: Place Bet - Enter Roll 2 Phase", %{state: state} do
      {c, s} = @seeds[3]
      {:ok, state} = Engine.roll_dice(state, "p1", c, s)

      # Bet 100
      {:ok, state} = Engine.place_bet(state, "p1", 100)

      assert state.phase == :rolling_2
      assert state.pending_bet == 100
      assert state.current_turn == "p1"
    end

    test "Roll 2: Win (Roll 5 > Roll 3)", %{state: state} do
      # Setup Roll 1 (3)
      {c1, s1} = @seeds[3]
      {:ok, state} = Engine.roll_dice(state, "p1", c1, s1)
      {:ok, state} = Engine.place_bet(state, "p1", 150)

      # Roll 2 (5)
      {c2, s2} = @seeds[5]
      {:ok, state} = Engine.roll_dice(state, "p1", c2, s2)

      # Check Win
      # Fee 5% of 150 = 7.5 -> 7
      # Win Amount = 150 - 7 = 143
      # New Pot = 200 - 150 = 50
      # Player Balance = 900 + 143 = 1043

      assert state.current_turn == "p2"
      assert state.pot == 50
      assert state.players["p1"].balance == 1043
    end

    test "Roll 2: Lose (Roll 2 <= Roll 3)", %{state: state} do
      # Setup Roll 1 (3)
      {c1, s1} = @seeds[3]
      {:ok, state} = Engine.roll_dice(state, "p1", c1, s1)
      {:ok, state} = Engine.place_bet(state, "p1", 150)

      # Roll 2 (2)
      {c2, s2} = @seeds[2]
      {:ok, state} = Engine.roll_dice(state, "p1", c2, s2)

      # Check Loss
      # Player pays 150 to pot
      # New Pot = 200 + 150 = 350
      # Player Balance = 900 - 150 = 750

      assert state.current_turn == "p2"
      assert state.pot == 350
      assert state.players["p1"].balance == 750
    end

    test "Roll 2: Lose (Tie) (Roll 3 == Roll 3)", %{state: state} do
      # Setup Roll 1 (3)
      {c1, s1} = @seeds[3]
      {:ok, state} = Engine.roll_dice(state, "p1", c1, s1)
      {:ok, state} = Engine.place_bet(state, "p1", 150)

      # Roll 2 (3)
      {c2, s2} = @seeds[3]
      {:ok, state} = Engine.roll_dice(state, "p1", c2, s2)

      # Tie is loss
      assert state.pot == 350
      assert state.players["p1"].balance == 750
    end
  end

  describe "Management and Timeouts" do
    setup :start_2_players

    test "Remove Player: Active player removed", %{state: state} do
      assert state.current_turn == "p1"
      {:ok, state} = Engine.remove_player(state, "p1")

      assert state.current_turn == "p2"
      assert not Map.has_key?(state.players, "p1")
      assert state.turn_order == ["p2"]
    end

    test "Remove Player: Idle player removed", %{state: state} do
      assert state.current_turn == "p1"
      {:ok, state} = Engine.remove_player(state, "p2")

      assert state.current_turn == "p1" # No change
      assert not Map.has_key?(state.players, "p2")
      assert state.turn_order == ["p1"]
    end

    test "Timeout: Roll 1 passes turn", %{state: state} do
      assert state.current_turn == "p1"
      assert state.phase == :rolling_1

      {:ok, state} = Engine.handle_timeout(state)

      assert state.current_turn == "p2"
      assert state.phase == :rolling_1
    end

    test "Timeout: Deciding passes turn (skip)", %{state: state} do
      # Move to deciding
      {c, s} = @seeds[3]
      {:ok, state} = Engine.roll_dice(state, "p1", c, s)
      assert state.phase == :deciding

      {:ok, state} = Engine.handle_timeout(state)

      assert state.current_turn == "p2"
      assert state.phase == :rolling_1
    end

    test "Timeout: Roll 2 loses bet to pot", %{state: state} do
      # Move to rolling_2
      {c, s} = @seeds[3]
      {:ok, state} = Engine.roll_dice(state, "p1", c, s)
      {:ok, state} = Engine.place_bet(state, "p1", 100)
      assert state.phase == :rolling_2

      {:ok, state} = Engine.handle_timeout(state)

      assert state.current_turn == "p2"
      assert state.players["p1"].balance == 800 # 900 - 100 lost
      assert state.pot == 300 # 200 + 100
    end
  end
end
