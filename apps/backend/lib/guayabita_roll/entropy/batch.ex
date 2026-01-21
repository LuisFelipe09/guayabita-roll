defmodule GuayabitaRoll.Entropy.Batch do
  @moduledoc """
  Schema para un lote de semillas con su Merkle Root.
  Cada batch contiene N semillas y se publica a EigenDA como unidad.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "entropy_batches" do
    field :merkle_root, :string
    field :size, :integer
    field :status, :string, default: "pending"
    field :eigenda_blob_id, :string
    field :published_at, :utc_datetime

    has_many :seeds, GuayabitaRoll.Entropy.Seed

    timestamps(type: :utc_datetime)
  end

  @required_fields [:merkle_root, :size]
  @optional_fields [:status, :eigenda_blob_id, :published_at]

  def changeset(batch, attrs) do
    batch
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:status, ["pending", "published", "expired"])
    |> unique_constraint(:merkle_root)
  end

  def publish_changeset(batch, blob_id) do
    batch
    |> change(%{
      status: "published",
      eigenda_blob_id: blob_id,
      published_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
  end
end
