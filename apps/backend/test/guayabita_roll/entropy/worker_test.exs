defmodule GuayabitaRoll.Entropy.WorkerTest do
  use GuayabitaRoll.DataCase, async: false
  require Logger
  
  alias GuayabitaRoll.Entropy.{Worker, Manager, Batch}
  alias GuayabitaRoll.Repo
  
  import ExUnit.CaptureLog

  setup do
    # Ajustar nivel de log para capturar info
    Logger.configure(level: :info)
    # Asegurarnos de que no hay batches previos para tener stock 0
    Repo.delete_all(Batch)
    :ok
  end

  test "automatically creates a batch when stock is low" do
    # Iniciamos el worker con un stock mínimo de 1 para forzar la creación de solo 1 lote
    # y un batch_size pequeño para el test
    opts = [min_stock: 1, batch_size: 16, check_interval: 1000, name: :test_worker_stock]
    
    # Capturamos el log para verificar que se dispara la acción
    assert capture_log(fn ->
      {:ok, pid} = Worker.start_link(opts)
      Ecto.Adapters.SQL.Sandbox.allow(GuayabitaRoll.Repo, self(), pid)
      
      # Esperamos un poco a que el proceso haga su primer chequeo
      Process.sleep(500)
      
      # Verificamos que se creó el batch
      assert Manager.total_available_seeds_count() == 16
      
      # Limpieza
      GenServer.stop(pid)
    end) =~ "Generando"
  end

  test "syncs pending batches with EigenDA" do
    # 1. Creamos un batch manualmente (que estará en estado 'pending')
    {:ok, batch} = Manager.create_batch(16)
    assert batch.status == "pending"

    # 2. Iniciamos el worker
    opts = [min_stock: 0, check_interval: 100, name: :test_worker_sync]
    {:ok, pid} = Worker.start_link(opts)
    Ecto.Adapters.SQL.Sandbox.allow(GuayabitaRoll.Repo, self(), pid)
    
    # 3. Esperamos al ciclo de sincronización
    Process.sleep(500)
    
    # 4. Verificamos que el batch ahora está publicado
    updated_batch = Repo.get(Batch, batch.id)
    assert updated_batch.status == "published"
    assert updated_batch.eigenda_blob_id != nil
    
    # Limpieza
    GenServer.stop(pid)
  end

  test "does NOT generate batches when stock is sufficient" do
    # 1. Creamos un batch para tener stock suficiente
    {:ok, _batch} = Manager.create_batch(32)
    initial_count = Manager.total_available_seeds_count()
    assert initial_count == 32

    # 2. Iniciamos el worker con min_stock bajo (16)
    opts = [min_stock: 16, batch_size: 16, check_interval: 100, name: :test_worker_sufficient]
    
    log = capture_log(fn ->
      {:ok, pid} = Worker.start_link(opts)
      Ecto.Adapters.SQL.Sandbox.allow(GuayabitaRoll.Repo, self(), pid)
      Process.sleep(300)
      
      # Stock debe permanecer igual
      assert Manager.total_available_seeds_count() == 32
      
      GenServer.stop(pid)
    end)
    
    # No debe haber log de generación
    refute log =~ "Generando"
  end

  test "generates multiple batches when deficit is large" do
    # Con min_stock=50 y batch_size=16, si tenemos 0 necesitamos ceil(50/16)=4 batches
    opts = [min_stock: 50, batch_size: 16, check_interval: 1000, name: :test_worker_multi]
    
    log = capture_log(fn ->
      {:ok, pid} = Worker.start_link(opts)
      Ecto.Adapters.SQL.Sandbox.allow(GuayabitaRoll.Repo, self(), pid)
      Process.sleep(500)
      
      # Debe haber generado 4 batches = 64 semillas
      count = Manager.total_available_seeds_count()
      assert count == 64  # 4 * 16
      
      GenServer.stop(pid)
    end)
    
    # Debe indicar que genera 4 lotes
    assert log =~ "Generando 4 lote(s)"
  end
end
