defmodule Validator.ValidatorSigningRate do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :validator_id, 1, type: :bytes, json_name: "validatorId"
  field :signed_batches, 2, type: :uint64, json_name: "signedBatches"
  field :unsigned_batches, 3, type: :uint64, json_name: "unsignedBatches"
  field :signed_bytes, 4, type: :uint64, json_name: "signedBytes"
  field :unsigned_bytes, 5, type: :uint64, json_name: "unsignedBytes"
  field :signing_latency, 6, type: :uint64, json_name: "signingLatency"
end

defmodule Validator.QuorumSigningRate do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :quorum_id, 1, type: :uint32, json_name: "quorumId"
  field :validator_signing_rates, 2, repeated: true, type: Validator.ValidatorSigningRate, json_name: "validatorSigningRates"
end

defmodule Validator.SigningRateBucket do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :start_timestamp, 1, type: :uint64, json_name: "startTimestamp"
  field :end_timestamp, 2, type: :uint64, json_name: "endTimestamp"
  field :quorum_signing_rates, 3, repeated: true, type: Validator.QuorumSigningRate, json_name: "quorumSigningRates"
end
