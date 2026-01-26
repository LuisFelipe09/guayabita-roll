defmodule Common.V2.BlobHeader do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :version, 1, type: :uint32
  field :quorum_numbers, 2, repeated: true, type: :uint32, json_name: "quorumNumbers"
  field :commitment, 3, type: Common.BlobCommitment
  field :payment_header, 4, type: Common.V2.PaymentHeader, json_name: "paymentHeader"
end

defmodule Common.V2.BlobCertificate do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :blob_header, 1, type: Common.V2.BlobHeader, json_name: "blobHeader"
  field :signature, 2, type: :bytes
  field :relay_keys, 3, repeated: true, type: :uint32, json_name: "relayKeys"
end

defmodule Common.V2.BatchHeader do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :batch_root, 1, type: :bytes, json_name: "batchRoot"
  field :reference_block_number, 2, type: :uint64, json_name: "referenceBlockNumber"
end

defmodule Common.V2.Batch do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :header, 1, type: Common.V2.BatchHeader
  field :blob_certificates, 2, repeated: true, type: Common.V2.BlobCertificate, json_name: "blobCertificates"
end

defmodule Common.V2.PaymentHeader do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field :account_id, 1, type: :string, json_name: "accountId"
  field :timestamp, 2, type: :int64
  field :cumulative_payment, 3, type: :bytes, json_name: "cumulativePayment"
end
