defmodule GuayabitaRoll.Game.Engine do
  @moduledoc """
  Motor de lógica pura para el juego Guayabita Roll.
  Gestiona las transiciones de estado, reglas de negocio y cálculo de resultados.
  """

  alias GuayabitaRoll.Game.{State, Player}

  @doc """
  Inicializa una nueva partida.
  """
  def new_game(id, min_bet) do
    State.new(id, min_bet)
  end

  @doc """
  Agrega un jugador a la mesa.
  Retorna {:ok, state} o {:error, reason}.
  """
  def add_player(%State{} = state, player_id, name, balance) do
    if Map.has_key?(state.players, player_id) do
      {:error, :player_already_joined}
    else
      player = Player.new(player_id, name, balance)
      new_players = Map.put(state.players, player_id, player)
      # Agregar al final de la cola si el juego ya inició (opcional, por ahora solo al inicio)
      new_order = state.turn_order ++ [player_id]

      {:ok, %{state | players: new_players, turn_order: new_order}}
    end
  end

  @doc """
  Inicia una nueva ronda.
  Cobra la apuesta inicial (Casado) a todos los jugadores activos.
  """
  def start_round(%State{} = state) do
    cond do
      map_size(state.players) == 0 ->
        {:error, :no_players}

      state.phase not in [:waiting_start, :finished] ->
        {:error, :game_in_progress}

      true ->
        # Cobrar Casado (Entry Fee)
        {updated_players, total_ante, failures} = collect_ante(state.players, state.min_bet)

        if length(failures) > 0 do
          # Si alguien no puede pagar, quizas deberíamos sacarlo o retornar error.
          # Por simplicidad, retornamos error.
          {:error, {:insufficient_funds, failures}}
        else
          first_player = List.first(state.turn_order)

          new_state = %{state |
            players: updated_players,
            pot: state.pot + total_ante,
            current_turn: first_player,
            phase: :rolling_1,
            current_roll_val: nil,
            pending_bet: nil,
            winner_id: nil,
            last_event: %{type: :round_started, pot: state.pot + total_ante}
          }

          {:ok, new_state}
        end
    end
  end

  @doc """
  Ejecuta el primer lanzamiento de dados (o el segundo si ya se apostó).

  Esta función determina si es el primer o segundo tiro basado en el estado.

  ## Parámetros
  - `client_seed`: Semilla del cliente (hex string).
  - `server_seed`: Semilla del servidor (hex string).
  """
  def roll_dice(%State{} = state, player_id, client_seed, server_seed) do
    with :ok <- validate_turn(state, player_id),
         :ok <- validate_phase_for_roll(state) do

      # Calcular resultado determinista (1-6)
      dice_result = calculate_outcome(client_seed, server_seed)

      apply_roll_result(state, player_id, dice_result, state.phase)
    end
  end

  @doc """
  El jugador decide apostar una cantidad del pote (Solo si sacó 3 o 4).
  """
  def place_bet(%State{} = state, player_id, amount) do
    with :ok <- validate_turn(state, player_id),
         :ok <- validate_phase(state, :deciding),
         :ok <- validate_bet_amount(state, amount) do

      new_state = %{state |
        phase: :rolling_2,
        pending_bet: amount,
        last_event: %{type: :bet_placed, player_id: player_id, amount: amount}
      }

      {:ok, new_state}
    end
  end

  @doc """
  El jugador decide NO apostar (Pasar).
  Equivale a perder el turno.
  """
  def skip_bet(%State{} = state, player_id) do
    with :ok <- validate_turn(state, player_id),
         :ok <- validate_phase(state, :deciding) do

      next_turn(state, "Player skipped bet")
    end
  end

  @doc """
  Elimina un jugador de la mesa.
  Si es su turno, pasa al siguiente.
  """
  def remove_player(%State{} = state, player_id) do
    if not Map.has_key?(state.players, player_id) do
      {:error, :player_not_found}
    else
      # Calcular siguiente turno con el estado original
      idx = Enum.find_index(state.turn_order, &(&1 == player_id))
      len = length(state.turn_order)

      next_player =
        if len > 1 do
          next_idx = rem(idx + 1, len)
          Enum.at(state.turn_order, next_idx)
        else
          nil
        end

      # Actualizar listas
      players = Map.delete(state.players, player_id)
      turn_order = List.delete(state.turn_order, player_id)

      updated_state_base = %{state | players: players, turn_order: turn_order}

      if state.current_turn == player_id do
         if next_player == nil or next_player == player_id do
            # Era el único jugador
            {:ok, %{updated_state_base | current_turn: nil, phase: :waiting_start}}
         else
            # Avanzar turno al calculado
            new_state = %{updated_state_base |
               current_turn: next_player,
               phase: :rolling_1,
               current_roll_val: nil,
               pending_bet: nil,
               last_event: %{type: :player_left, player_id: player_id}
            }
            {:ok, new_state}
         end
      else
         {:ok, updated_state_base}
      end
    end
  end

  @doc """
  Maneja el timeout del turno actual.
  Aplica penalidades según la fase.
  """
  def handle_timeout(%State{} = state) do
    if state.phase in [:waiting_start, :finished] or state.current_turn == nil do
       {:ok, state}
    else
       player = state.players[state.current_turn]

       case state.phase do
         :rolling_2 ->
            # Pérdida automática. Apuesta al pote.
            bet = state.pending_bet
            actual_loss = min(player.balance, bet)
            new_balance = player.balance - actual_loss
            new_pot = state.pot + actual_loss

            new_players = Map.put(state.players, state.current_turn, %{player | balance: new_balance})

            state = %{state | players: new_players, pot: new_pot}
            next_turn(state, "Timeout in Roll 2 (Lost #{actual_loss})")

         :deciding ->
            # Equivalente a skip_bet
            next_turn(state, "Timeout in Decision (Skipped)")

         :rolling_1 ->
            # Pierde turno
            next_turn(state, "Timeout in Roll 1")

         _ ->
            next_turn(state, "Timeout")
       end
    end
  end

  # --- Private Helpers ---

  defp collect_ante(players, amount) do
    Enum.reduce(players, {%{}, 0, []}, fn {pid, p}, {acc_players, acc_total, failures} ->
      if p.balance >= amount do
        updated_p = %{p | balance: p.balance - amount}
        {Map.put(acc_players, pid, updated_p), acc_total + amount, failures}
      else
        {acc_players, acc_total, failures ++ [pid]}
      end
    end)
  end

  defp validate_turn(state, player_id) do
    if state.current_turn == player_id do
      :ok
    else
      {:error, :not_your_turn}
    end
  end

  defp validate_phase(state, required_phase) do
    if state.phase == required_phase do
      :ok
    else
      {:error, {:invalid_phase, state.phase}}
    end
  end

  defp validate_phase_for_roll(state) do
    if state.phase in [:rolling_1, :rolling_2] do
      :ok
    else
      {:error, :waiting_decision_or_start}
    end
  end

  defp validate_bet_amount(state, amount) do
    player = state.players[state.current_turn]
    cond do
      amount < state.min_bet -> {:error, :bet_too_low}
      amount > state.pot -> {:error, :bet_exceeds_pot}
      amount > player.balance -> {:error, :insufficient_balance_to_cover_bet}
      true -> :ok
    end
  end

  # Lógica de reglas de Guayabita
  defp apply_roll_result(state, player_id, result, :rolling_1) do
    case result do
      # 1 o 6: Sale (Pierde turno)
      x when x in [1, 6] ->
        next_turn(state, "Rolled #{x} (Sale)")

      # 2 o 5: Pone (Paga 1 unidad al pote)
      x when x in [2, 5] ->
        player = state.players[player_id]
        amount_to_pay = state.min_bet

        # Si no tiene suficiente, pone lo que tiene (o se elimina? reglas estándar dicen pone)
        # Asumiremos que debe poner. Si no puede, ¿queda debiendo o se va all-in?
        # Simplificación: Pone hasta donde le alcance, si es 0, mala suerte.
        # Pero para consistencia, restamos.

        if player.balance >= amount_to_pay do
          new_balance = player.balance - amount_to_pay
          new_player = %{player | balance: new_balance}
          new_players = Map.put(state.players, player_id, new_player)
          new_pot = state.pot + amount_to_pay

          state = %{state | players: new_players, pot: new_pot}
          next_turn(state, "Rolled #{x} (Pone #{amount_to_pay})")
        else
           # Caso borde: No tiene para pagar la multa.
           # Lo eliminamos o simplemente pasa? "Pone" es obligatorio.
           # Dejaremos que quede en 0 o negativo? No, balance no debe ser negativo.
           # Pone lo que le queda.
           actual_pay = player.balance
           new_player = %{player | balance: 0, status: :eliminated} # O :broke
           new_players = Map.put(state.players, player_id, new_player)
           new_pot = state.pot + actual_pay

           state = %{state | players: new_players, pot: new_pot}
           next_turn(state, "Rolled #{x} (Pone #{actual_pay} and went broke)")
        end

      # 3 o 4: Apuesta (Decide)
      x when x in [3, 4] ->
        new_state = %{state |
          phase: :deciding,
          current_roll_val: x,
          last_event: %{type: :rolled, value: x, msg: "Rolled #{x} (Decision)"}
        }
        {:ok, new_state}
    end
  end

  defp apply_roll_result(state, player_id, result, :rolling_2) do
    # Segundo lanzamiento
    first_roll = state.current_roll_val
    bet = state.pending_bet
    player = state.players[player_id]

    cond do
      # Gana: Segundo > Primero
      result > first_roll ->
        # Gana la apuesta del pote
        # Se descuenta fee del protocolo? "El motor debe calcular un pequeño % de comisión"
        # Asumamos Fee del 5% por ahora (hardcoded o config)
        fee_percent = 0.05
        fee = trunc(bet * fee_percent)

        # Clarificación: "El jugador tiene la opción de apostar una cantidad del pote."
        # Si gana: "Gana la cantidad apostada del pote." -> Pote disminuye, jugador aumenta.
        # Si pierde: "La apuesta se suma al pote." -> Jugador paga al pote.

        # Caso Ganar:
        # Pote = Pote - Bet
        # Jugador = Jugador + (Bet - Fee)
        # Treasury = Treasury + Fee (No tracked in State yet, maybe just logged)

        new_pot = state.pot - bet
        new_player_balance = player.balance + (bet - fee)

        updated_player = %{player | balance: new_player_balance}
        new_players = Map.put(state.players, player_id, updated_player)

        event_msg = "Rolled #{result} vs #{first_roll} (WON #{bet - fee})"
        state = %{state | players: new_players, pot: new_pot}
        next_turn(state, event_msg)

      # Pierde: Segundo <= Primero
      result <= first_roll ->
        # Jugador paga la apuesta al pote
        # Debe tener saldo suficiente. El chequeo se hizo en place_bet?
        # En place_bet verificamos `amount <= state.pot`.
        # Pero, ¿verificamos si el jugador TIENE ese dinero para pagar si pierde?
        # Regla: "Si el segundo dado es MENOR o IGUAL... el jugador pierde la apuesta y esta se suma al pote."
        # Esto implica que el jugador PONE dinero de su bolsillo.

        # Revisión: `place_bet` debe verificar `player.balance >= amount`.

        amount_lost = bet

        # Ajustamos balance
        # Nota: Si validamos antes, no debería haber error aquí, pero manejaremos fondos insuficientes.
        actual_loss = min(player.balance, amount_lost)

        new_player_balance = player.balance - actual_loss
        new_pot = state.pot + actual_loss

        updated_player = %{player | balance: new_player_balance}
        new_players = Map.put(state.players, player_id, updated_player)

        event_msg = "Rolled #{result} vs #{first_roll} (LOST #{actual_loss})"
        state = %{state | players: new_players, pot: new_pot}
        next_turn(state, event_msg)
    end
  end

  # Avanza al siguiente turno
  defp next_turn(state, msg) do
    # Buscar índice actual
    current_idx = Enum.find_index(state.turn_order, &(&1 == state.current_turn))

    # Siguiente índice (circular)
    next_idx = rem(current_idx + 1, length(state.turn_order))
    next_player_id = Enum.at(state.turn_order, next_idx)

    # Limpiar estado temporal
    new_state = %{state |
      current_turn: next_player_id,
      phase: :rolling_1,
      current_roll_val: nil,
      pending_bet: nil,
      last_event: %{type: :turn_change, msg: msg, prev_player: state.current_turn, next_player: next_player_id}
    }

    {:ok, new_state}
  end

  defp calculate_outcome(client_seed, server_seed) do
    # Concatenar semillas
    # Asumimos que vienen en hex string.
    # Provably Fair standard: Keccak256(ServerSeed + ClientSeed)
    # ServerSeed debería ser el reveal.

    combined = server_seed <> client_seed
    hash = ExKeccak.hash_256(combined)

    # Tomar los primeros bytes para el entero (o convertir todo el hash)
    # :binary.decode_unsigned(hash) % 6 + 1
    # Usamos BigInt para uniformidad
    int_val = :binary.decode_unsigned(hash)
    rem(int_val, 6) + 1
  end
end
