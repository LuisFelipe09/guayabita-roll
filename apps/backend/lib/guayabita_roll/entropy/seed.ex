defmodule GuayabitaRoll.Entropy.Seed do
  @moduledoc """
  Schema para una semilla individual dentro de un batch.
  Cada semilla tiene un índice en el Merkle Tree y puede generar su proof.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "entropy_seeds" do
    field :index, :integer
    field :seed, :string
    field :hash, :string
    field :status, :string, default: "available"
    field :used_at, :utc_datetime
    field :game_id, :binary_id

    belongs_to :batch, GuayabitaRoll.Entropy.Batch

    timestamps(type: :utc_datetime)
  end

  @required_fields [:batch_id, :index, :seed, :hash]
  @optional_fields [:status, :used_at, :game_id]

  def changeset(seed, attrs) do
    seed
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:status, ["available", "reserved", "used", "expired"])
    |> validate_number(:index, greater_than_or_equal_to: 0)
    |> unique_constraint([:batch_id, :index])
    |> unique_constraint(:hash)
    |> foreign_key_constraint(:batch_id)
  end

  def reserve_changeset(seed) do
    change(seed, %{status: "reserved"})
  end

  def use_changeset(seed, game_id) do
    change(seed, %{
      status: "used",
      game_id: game_id,
      used_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
  end
end
