defmodule Disperser.V2.BlobStatus do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :UNKNOWN, 0
  field :QUEUED, 1
  field :ENCODED, 2
  field :GATHERING_SIGNATURES, 3
  field :COMPLETE, 4
  field :FAILED, 5
end

defmodule Disperser.V2.DisperseBlobRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :blob, 1, type: :bytes
  field :blob_header, 2, type: Common.V2.BlobHeader, json_name: "blobHeader"
  field :signature, 3, type: :bytes
  field :anchor_signature, 5, type: :bytes, json_name: "anchorSignature"
  field :disperser_id, 6, type: :uint32, json_name: "disperserId"
  field :chain_id, 7, type: :bytes, json_name: "chainId"
end

defmodule Disperser.V2.DisperseBlobReply do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :result, 1, type: Disperser.V2.BlobStatus, enum: true
  field :blob_key, 2, type: :bytes, json_name: "blobKey"
end

defmodule Disperser.V2.BlobStatusRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :blob_key, 1, type: :bytes, json_name: "blobKey"
end

defmodule Disperser.V2.BlobStatusReply do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :status, 1, type: Disperser.V2.BlobStatus, enum: true
  field :signed_batch, 2, type: Disperser.V2.SignedBatch, json_name: "signedBatch"
  field :blob_inclusion_info, 3, type: Disperser.V2.BlobInclusionInfo, json_name: "blobInclusionInfo"
end

defmodule Disperser.V2.BlobCommitmentRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :blob, 1, type: :bytes
end

defmodule Disperser.V2.BlobCommitmentReply do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :blob_commitment, 1, type: Common.BlobCommitment, json_name: "blobCommitment"
end

defmodule Disperser.V2.GetPaymentStateRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :account_id, 1, type: :string, json_name: "accountId"
  field :signature, 2, type: :bytes
  field :timestamp, 3, type: :uint64
end

defmodule Disperser.V2.GetPaymentStateReply do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :payment_global_params, 1, type: Disperser.V2.PaymentGlobalParams, json_name: "paymentGlobalParams"
  field :period_records, 2, repeated: true, type: Disperser.V2.PeriodRecord, json_name: "periodRecords"
  field :reservation, 3, type: Disperser.V2.Reservation
  field :cumulative_payment, 4, type: :bytes, json_name: "cumulativePayment"
  field :onchain_cumulative_payment, 5, type: :bytes, json_name: "onchainCumulativePayment"
end

defmodule Disperser.V2.SignedBatch do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :header, 1, type: Common.V2.BatchHeader
  field :attestation, 2, type: Disperser.V2.Attestation
end

defmodule Disperser.V2.BlobInclusionInfo do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :blob_certificate, 1, type: Common.V2.BlobCertificate, json_name: "blobCertificate"
  field :blob_index, 2, type: :uint32, json_name: "blobIndex"
  field :inclusion_proof, 3, type: :bytes, json_name: "inclusionProof"
end

defmodule Disperser.V2.Attestation do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :non_signer_pubkeys, 1, repeated: true, type: :bytes, json_name: "nonSignerPubkeys"
  field :apk_g2, 2, type: :bytes, json_name: "apkG2"
  field :quorum_apks, 3, repeated: true, type: :bytes, json_name: "quorumApks"
  field :sigma, 4, type: :bytes
  field :quorum_numbers, 5, repeated: true, type: :uint32, json_name: "quorumNumbers"
  field :quorum_signed_percentages, 6, type: :bytes, json_name: "quorumSignedPercentages"
end

defmodule Disperser.V2.PaymentGlobalParams do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :global_symbols_per_second, 1, type: :uint64, json_name: "globalSymbolsPerSecond"
  field :min_num_symbols, 2, type: :uint64, json_name: "minNumSymbols"
  field :price_per_symbol, 3, type: :uint64, json_name: "pricePerSymbol"
  field :reservation_window, 4, type: :uint64, json_name: "reservationWindow"
  field :on_demand_quorum_numbers, 5, repeated: true, type: :uint32, json_name: "onDemandQuorumNumbers"
end

defmodule Disperser.V2.Reservation do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :symbols_per_second, 1, type: :uint64, json_name: "symbolsPerSecond"
  field :start_timestamp, 2, type: :uint32, json_name: "startTimestamp"
  field :end_timestamp, 3, type: :uint32, json_name: "endTimestamp"
  field :quorum_numbers, 4, repeated: true, type: :uint32, json_name: "quorumNumbers"
  field :quorum_splits, 5, repeated: true, type: :uint32, json_name: "quorumSplits"
end

defmodule Disperser.V2.PeriodRecord do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :index, 1, type: :uint32
  field :usage, 2, type: :uint64
end

defmodule Disperser.V2.GetValidatorSigningRateRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :validator_id, 1, type: :bytes, json_name: "validatorId"
  field :quorum, 2, type: :uint32
  field :start_timestamp, 3, type: :uint64, json_name: "startTimestamp"
  field :end_timestamp, 4, type: :uint64, json_name: "endTimestamp"
end

defmodule Disperser.V2.GetValidatorSigningRateReply do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :validator_signing_rate, 1, type: Validator.ValidatorSigningRate, json_name: "validatorSigningRate"
end

defmodule Disperser.V2.Disperser.Service do
  @moduledoc false

  use GRPC.Service, name: "disperser.v2.Disperser", protoc_gen_elixir_version: "0.12.0"

  rpc :DisperseBlob, Disperser.V2.DisperseBlobRequest, Disperser.V2.DisperseBlobReply
  rpc :GetBlobStatus, Disperser.V2.BlobStatusRequest, Disperser.V2.BlobStatusReply
  rpc :GetBlobCommitment, Disperser.V2.BlobCommitmentRequest, Disperser.V2.BlobCommitmentReply
  rpc :GetPaymentState, Disperser.V2.GetPaymentStateRequest, Disperser.V2.GetPaymentStateReply
  rpc :GetValidatorSigningRate, Disperser.V2.GetValidatorSigningRateRequest, Disperser.V2.GetValidatorSigningRateReply
end

defmodule Disperser.V2.Disperser.Stub do
  @moduledoc false

  use GRPC.Stub, service: Disperser.V2.Disperser.Service
end
