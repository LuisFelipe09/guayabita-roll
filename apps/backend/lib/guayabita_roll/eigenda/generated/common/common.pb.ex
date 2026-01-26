defmodule Common.G1Commitment do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :x, 1, type: :bytes
  field :y, 2, type: :bytes
end

defmodule Common.BlobCommitment do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :commitment, 1, type: :bytes
  field :length_commitment, 2, type: :bytes, json_name: "lengthCommitment"
  field :length_proof, 3, type: :bytes, json_name: "lengthProof"
  field :length, 4, type: :uint32
end
