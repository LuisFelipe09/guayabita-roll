defmodule GuayabitaRoll.Entropy.Manager do
  @moduledoc """
  Gestiona la generación y persistencia de lotes de entropía.
  
  Este módulo es el "seeder" que:
  1. Genera N semillas usando GuayabitaRoll.Entropy
  2. Construye el Merkle Tree
  3. Persiste el batch y las semillas en PostgreSQL
  
  ## Uso
  
      # Generar un batch de 1000 semillas
      {:ok, batch} = GuayabitaRoll.Entropy.Manager.create_batch(1000)
      
      # Obtener una semilla disponible
      {:ok, seed} = GuayabitaRoll.Entropy.Manager.get_available_seed()
      
      # Marcar semilla como usada
      {:ok, seed} = GuayabitaRoll.Entropy.Manager.use_seed(seed, game_id)
  """

  alias GuayabitaRoll.Repo
  alias GuayabitaRoll.Entropy
  alias GuayabitaRoll.Entropy.{Batch, Seed}

  import Ecto.Query

  # MerkleTree requires power of 2 elements
  @default_batch_size 1024

  @doc """
  Crea un nuevo batch de semillas y las persiste en la base de datos.
  
  ## Opciones
  - `size` - Número de semillas a generar (default: 1000)
  
  ## Retorno
  `{:ok, batch}` con el batch creado incluyendo todas las semillas.
  """
  def create_batch(size \\ @default_batch_size) do
    # 1. Generar todas las semillas
    seed_pairs = Enum.map(1..size, fn _ -> Entropy.generate_seed_pair() end)
    
    # 2. Extraer los hashes para el Merkle Tree
    hashes = Enum.map(seed_pairs, & &1.hash)
    
    # 3. Construir el Merkle Tree y obtener la raíz
    tree = Entropy.build_batch(hashes)
    merkle_root = Entropy.root_hash(tree)
    
    # 4. Persistir en una transacción
    Repo.transaction(fn ->
      # Crear el batch
      {:ok, batch} = 
        %Batch{}
        |> Batch.changeset(%{
          merkle_root: merkle_root,
          size: size
        })
        |> Repo.insert()
      
      # Crear las semillas con su índice
      seeds =
        seed_pairs
        |> Enum.with_index()
        |> Enum.map(fn {pair, index} ->
          %{
            batch_id: batch.id,
            index: index,
            seed: pair.seed,
            hash: pair.hash,
            inserted_at: DateTime.utc_now() |> DateTime.truncate(:second),
            updated_at: DateTime.utc_now() |> DateTime.truncate(:second)
          }
        end)
      
      # Insert en bulk para eficiencia
      {_count, _} = Repo.insert_all(Seed, seeds)
      
      # Retornar el batch con las semillas cargadas
      Repo.preload(batch, :seeds)
    end)
  end

  @doc """
  Obtiene una semilla disponible del batch más antiguo publicado.
  La marca como "reserved" para evitar race conditions.
  """
  def get_available_seed do
    query =
      from s in Seed,
        join: b in assoc(s, :batch),
        where: s.status == "available" and b.status == "published",
        order_by: [asc: b.inserted_at, asc: s.index],
        limit: 1,
        lock: "FOR UPDATE SKIP LOCKED"

    case Repo.one(query) do
      nil -> 
        {:error, :no_seeds_available}
      
      seed -> 
        seed
        |> Seed.reserve_changeset()
        |> Repo.update()
    end
  end

  @doc """
  Obtiene una semilla disponible de cualquier batch (incluyendo pending).
  Útil para testing o cuando aún no se ha integrado EigenDA.
  """
  def get_any_available_seed do
    query =
      from s in Seed,
        where: s.status == "available",
        order_by: [asc: s.inserted_at, asc: s.index],
        limit: 1,
        lock: "FOR UPDATE SKIP LOCKED"

    case Repo.one(query) do
      nil -> {:error, :no_seeds_available}
      seed -> 
        seed
        |> Seed.reserve_changeset()
        |> Repo.update()
    end
  end

  @doc """
  Marca una semilla como usada y la asocia a un juego.
  """
  def use_seed(%Seed{} = seed, game_id) do
    seed
    |> Seed.use_changeset(game_id)
    |> Repo.update()
  end

  @doc """
  Genera la prueba de Merkle para una semilla específica.
  Reconstruye el árbol del batch y genera la proof.
  """
  def generate_proof_for_seed(%Seed{} = seed) do
    seed = Repo.preload(seed, :batch)
    
    # Obtener todas las semillas del batch ordenadas por índice
    seeds_query =
      from s in Seed,
        where: s.batch_id == ^seed.batch_id,
        order_by: [asc: s.index]
    
    all_seeds = Repo.all(seeds_query)
    hashes = Enum.map(all_seeds, & &1.hash)
    
    # Reconstruir el árbol
    tree = Entropy.build_batch(hashes)
    
    # Generar la prueba
    proof = Entropy.generate_proof(tree, seed.index)
    
    {:ok, %{
      seed: seed.seed,
      hash: seed.hash,
      index: seed.index,
      merkle_root: seed.batch.merkle_root,
      proof: proof
    }}
  end

  @doc """
  Cuenta las semillas disponibles en batches publicados.
  """
  def available_seeds_count do
    query =
      from s in Seed,
        join: b in assoc(s, :batch),
        where: s.status == "available" and b.status == "published",
        select: count(s.id)

    Repo.one(query)
  end

  @doc """
  Cuenta las semillas disponibles en cualquier batch.
  """
  def total_available_seeds_count do
    query =
      from s in Seed,
        where: s.status == "available",
        select: count(s.id)

    Repo.one(query)
  end

  @doc """
  Publica un batch a EigenDA (placeholder para integración futura).
  """
  def publish_batch(%Batch{} = batch, blob_id) do
    batch
    |> Batch.publish_changeset(blob_id)
    |> Repo.update()
  end

  @doc """
  Obtiene un batch por su ID.
  """
  def get_batch(id), do: Repo.get(Batch, id)

  @doc """
  Obtiene un batch con sus semillas.
  """
  def get_batch_with_seeds(id) do
    Batch
    |> Repo.get(id)
    |> Repo.preload(:seeds)
  end

  @doc """
  Lista los batches que están en estado "pending".
  """
  def list_pending_batches do
    query =
      from b in Batch,
        where: b.status == "pending",
        order_by: [asc: b.inserted_at]

    Repo.all(query)
  end

  @doc """
  Marca un batch como "dispersing" (enviado a EigenDA, esperando confirmación).
  """
  def mark_batch_dispersing(%Batch{} = batch, request_id) do
    batch
    |> Ecto.Changeset.change(%{
      status: "dispersing",
      eigenda_blob_id: request_id
    })
    |> Repo.update()
  end

  @doc """
  Lista los batches que están en estado "dispersing" (esperando confirmación de EigenDA).
  """
  def list_dispersing_batches do
    query =
      from b in Batch,
        where: b.status == "dispersing",
        order_by: [asc: b.inserted_at]

    Repo.all(query)
  end

  @doc """
  Lista todos los batches con conteo de semillas por estado.
  """
  def list_batches do
    query =
      from b in Batch,
        left_join: s in assoc(b, :seeds),
        group_by: b.id,
        select: %{
          batch: b,
          total_seeds: count(s.id),
          available_seeds: sum(fragment("CASE WHEN ? = 'available' THEN 1 ELSE 0 END", s.status)),
          used_seeds: sum(fragment("CASE WHEN ? = 'used' THEN 1 ELSE 0 END", s.status))
        },
        order_by: [desc: b.inserted_at]

    Repo.all(query)
  end
end
