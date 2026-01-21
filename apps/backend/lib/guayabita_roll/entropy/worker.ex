defmodule GuayabitaRoll.Entropy.Worker do
  @moduledoc """
  Worker que automatiza la gestión de stock de semillas y sincronización con EigenDA.
  
  Responsabilidades:
  1. Garantizar Stock: Monitorea semillas disponibles y crea nuevos lotes si el stock es bajo.
  2. Sincronización EigenDA: Detecta batches pendientes y los "publica" (mock) generando un blob_id.
  """
  
  use GenServer
  require Logger

  alias GuayabitaRoll.Entropy.Manager

  # Configuración (Valores optimizados para producción)
  @check_interval :timer.minutes(1)  # 1 minuto entre chequeos
  @min_stock 5_000                   # Mínimo de semillas antes de generar
  @batch_size 2_048                  # Semillas por lote (potencia de 2)

  # Client API
  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  # Server Callbacks
  @impl true
  def init(opts) do
    Logger.info("[Entropy.Worker] Iniciando bodega de azar...")
    
    interval = Keyword.get(opts, :check_interval, @check_interval)
    
    # Programar el primer chequeo (usamos el mismo intervalo o 100ms para iniciar rápido)
    schedule_check(100)
    
    {:ok, %{
      check_interval: interval,
      min_stock: Keyword.get(opts, :min_stock, @min_stock),
      batch_size: Keyword.get(opts, :batch_size, @batch_size)
    }}
  end

  @impl true
  def handle_info(:check_stock_and_sync, state) do
    # 1. Garantizar Stock
    guarantee_stock(state)
    
    # 2. Sincronizar con EigenDA
    sync_with_eigenda()
    
    # Re-programar
    schedule_check(state.check_interval)
    
    {:noreply, state}
  end

  # Helpers internos
  
  defp schedule_check(interval) do
    Process.send_after(self(), :check_stock_and_sync, interval)
  end

  defp guarantee_stock(state) do
    available = Manager.total_available_seeds_count()
    
    if available < state.min_stock do
      # Calcular cuántos lotes necesitamos para alcanzar el stock mínimo
      deficit = state.min_stock - available
      batches_needed = max(1, ceil(deficit / state.batch_size))
      
      Logger.info("[Entropy.Worker] Stock bajo (#{available} < #{state.min_stock}). Generando #{batches_needed} lote(s)...")
      
      Enum.each(1..batches_needed, fn batch_num ->
        case Manager.create_batch(state.batch_size) do
          {:ok, batch} ->
            Logger.info("[Entropy.Worker] Lote #{batch_num}/#{batches_needed} generado: #{batch.id}")
          {:error, reason} ->
            Logger.error("[Entropy.Worker] Error al generar lote #{batch_num}: #{inspect(reason)}")
        end
      end)
    else
      Logger.debug("[Entropy.Worker] Stock saludable (#{available} semillas disponibles)")
    end
  end

  defp sync_with_eigenda do
    pending_batches = Manager.list_pending_batches()
    
    if Enum.any?(pending_batches) do
      Logger.info("[Entropy.Worker] Sincronizando #{length(pending_batches)} lotes con EigenDA...")
      
      Enum.each(pending_batches, fn batch ->
        # Aquí iría la llamada gRPC al Disperser de EigenDA
        # Por ahora simulamos una respuesta exitosa
        blob_id = "eigenda_blob_#{System.unique_integer([:positive, :monotonic])}"
        
        case Manager.publish_batch(batch, blob_id) do
          {:ok, _} ->
            Logger.info("[Entropy.Worker] Batch #{batch.id} publicado en EigenDA (Blob ID: #{blob_id})")
          {:error, reason} ->
            Logger.error("[Entropy.Worker] Error al marcar batch #{batch.id} como publicado: #{inspect(reason)}")
        end
      end)
    end
  end
end
