defmodule GuayabitaRoll.Repo.Migrations.CreateEntropyTables do
  use Ecto.Migration

  def change do
    # Tabla de lotes (batches) - cada lote tiene un Merkle Root
    create table(:entropy_batches, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :merkle_root, :string, null: false
      add :size, :integer, null: false
      add :status, :string, default: "pending"  # pending, published, expired
      add :eigenda_blob_id, :string  # ID del blob en EigenDA (opcional hasta publish)
      add :published_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:entropy_batches, [:merkle_root])
    create index(:entropy_batches, [:status])

    # Tabla de semillas individuales
    create table(:entropy_seeds, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :batch_id, references(:entropy_batches, type: :binary_id, on_delete: :delete_all), null: false
      add :index, :integer, null: false  # posición en el Merkle Tree (0-based)
      add :seed, :string, null: false    # semilla en hex (secreta hasta revelación)
      add :hash, :string, null: false    # keccak256(seed) en hex
      add :status, :string, default: "available"  # available, reserved, used, expired
      add :used_at, :utc_datetime
      add :game_id, :binary_id  # referencia al juego que la usó

      timestamps(type: :utc_datetime)
    end

    create unique_index(:entropy_seeds, [:batch_id, :index])
    create unique_index(:entropy_seeds, [:hash])
    create index(:entropy_seeds, [:status])
    create index(:entropy_seeds, [:batch_id])
  end
end
