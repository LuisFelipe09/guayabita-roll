defmodule GuayabitaRoll.Entropy.Worker do
  @moduledoc """
  Worker que automatiza la gestión de stock de semillas y sincronización con EigenDA.
  
  Responsabilidades:
  1. Garantizar Stock: Monitorea semillas disponibles y crea nuevos lotes si el stock es bajo.
  2. Sincronización EigenDA: Detecta batches pendientes y los publica en EigenDA.
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
      batch_size: Keyword.get(opts, :batch_size, @batch_size),
      eigenda_client: Keyword.get(opts, :eigenda_client, GuayabitaRoll.EigenDA.Client)
    }}
  end

  @impl true
  def handle_info(:check_stock_and_sync, state) do
    # 1. Garantizar Stock
    guarantee_stock(state)
    
    # 2. Sincronizar con EigenDA
    sync_with_eigenda(state)
    
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

  defp sync_with_eigenda(state) do
    # Fase 1: Dispersar batches pendientes
    disperse_pending_batches(state)
    
    # Fase 2: Confirmar batches que están siendo dispersados
    confirm_dispersing_batches(state)
  end

  defp disperse_pending_batches(state) do
    pending_batches = Manager.list_pending_batches()
    
    if Enum.any?(pending_batches) do
      Logger.info("[Entropy.Worker] Dispersando #{length(pending_batches)} lote(s) pendiente(s)...")
      
      Enum.each(pending_batches, fn batch ->
        data = Base.decode16!(batch.merkle_root, case: :lower)
        
        case state.eigenda_client.disperse_blob(data) do
          {:ok, request_id} ->
            blob_id = Base.encode16(request_id)
            
            # Marcar como "dispersing" (en proceso de confirmación)
            case Manager.mark_batch_dispersing(batch, blob_id) do
              {:ok, _} ->
                Logger.info("[Entropy.Worker] Batch #{batch.id} enviado a EigenDA. Request ID: #{blob_id}")
              {:error, reason} ->
                Logger.error("[Entropy.Worker] Error al marcar batch #{batch.id} como dispersing: #{inspect(reason)}")
            end
            
          {:error, reason} ->
            Logger.error("[Entropy.Worker] Error al dispersar batch #{batch.id}: #{inspect(reason)}")
        end
      end)
    end
  end

  defp confirm_dispersing_batches(state) do
    dispersing_batches = Manager.list_dispersing_batches()
    
    if Enum.any?(dispersing_batches) do
      Logger.info("[Entropy.Worker] Verificando confirmación de #{length(dispersing_batches)} lote(s)...")
      
      Enum.each(dispersing_batches, fn batch ->
        # Decodificar el request_id almacenado
        request_id = Base.decode16!(batch.eigenda_blob_id, case: :mixed)
        
        # Consultar estado (sin polling bloqueante - solo una consulta)
        check_and_update_batch_status(state, batch, request_id)
      end)
    end
  end

  defp check_and_update_batch_status(state, batch, request_id) do
    # Solo hacemos UNA consulta, no un polling completo
    # El worker se ejecuta periódicamente, así que eventualmente se confirmará
    case state.eigenda_client.get_blob_status(request_id) do
      {:ok, _blob_info} ->
        # CONFIRMED o FINALIZED - marcar como published
        case Manager.publish_batch(batch, batch.eigenda_blob_id) do
          {:ok, _} ->
            Logger.info("[Entropy.Worker] Batch #{batch.id} CONFIRMADO en EigenDA!")
          {:error, reason} ->
            Logger.error("[Entropy.Worker] Error al marcar batch #{batch.id} como published: #{inspect(reason)}")
        end
        
      {:error, :timeout} ->
        Logger.debug("[Entropy.Worker] Batch #{batch.id} aún procesándose...")
        
      {:error, reason} ->
        Logger.warning("[Entropy.Worker] Error al verificar batch #{batch.id}: #{inspect(reason)}")
    end
  end
end


