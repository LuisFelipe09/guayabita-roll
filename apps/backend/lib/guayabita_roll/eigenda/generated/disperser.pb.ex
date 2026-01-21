defmodule Disperser.BlobStatus do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "disperser.BlobStatus",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.EnumDescriptorProto{
      name: "BlobStatus",
      value: [
        %Google.Protobuf.EnumValueDescriptorProto{
          name: "UNKNOWN",
          number: 0,
          options: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.EnumValueDescriptorProto{
          name: "PROCESSING",
          number: 1,
          options: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.EnumValueDescriptorProto{
          name: "CONFIRMED",
          number: 2,
          options: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.EnumValueDescriptorProto{
          name: "FAILED",
          number: 3,
          options: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.EnumValueDescriptorProto{
          name: "FINALIZED",
          number: 4,
          options: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.EnumValueDescriptorProto{
          name: "INSUFFICIENT_SIGNATURES",
          number: 5,
          options: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.EnumValueDescriptorProto{
          name: "DISPERSING",
          number: 6,
          options: nil,
          __unknown_fields__: []
        }
      ],
      options: nil,
      reserved_range: [],
      reserved_name: [],
      __unknown_fields__: []
    }
  end

  field :UNKNOWN, 0
  field :PROCESSING, 1
  field :CONFIRMED, 2
  field :FAILED, 3
  field :FINALIZED, 4
  field :INSUFFICIENT_SIGNATURES, 5
  field :DISPERSING, 6
end

defmodule Disperser.AuthenticatedRequest do
  @moduledoc false

  use Protobuf,
    full_name: "disperser.AuthenticatedRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "AuthenticatedRequest",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "disperse_request",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".disperser.DisperseBlobRequest",
          default_value: nil,
          options: nil,
          oneof_index: 0,
          json_name: "disperseRequest",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "authentication_data",
          extendee: nil,
          number: 2,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".disperser.AuthenticationData",
          default_value: nil,
          options: nil,
          oneof_index: 0,
          json_name: "authenticationData",
          proto3_optional: nil,
          __unknown_fields__: []
        }
      ],
      nested_type: [],
      enum_type: [],
      extension_range: [],
      extension: [],
      options: nil,
      oneof_decl: [
        %Google.Protobuf.OneofDescriptorProto{
          name: "payload",
          options: nil,
          __unknown_fields__: []
        }
      ],
      reserved_range: [],
      reserved_name: [],
      __unknown_fields__: []
    }
  end

  oneof :payload, 0

  field :disperse_request, 1,
    type: Disperser.DisperseBlobRequest,
    json_name: "disperseRequest",
    oneof: 0

  field :authentication_data, 2,
    type: Disperser.AuthenticationData,
    json_name: "authenticationData",
    oneof: 0
end

defmodule Disperser.AuthenticatedReply do
  @moduledoc false

  use Protobuf,
    full_name: "disperser.AuthenticatedReply",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "AuthenticatedReply",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "blob_auth_header",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".disperser.BlobAuthHeader",
          default_value: nil,
          options: nil,
          oneof_index: 0,
          json_name: "blobAuthHeader",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "disperse_reply",
          extendee: nil,
          number: 2,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".disperser.DisperseBlobReply",
          default_value: nil,
          options: nil,
          oneof_index: 0,
          json_name: "disperseReply",
          proto3_optional: nil,
          __unknown_fields__: []
        }
      ],
      nested_type: [],
      enum_type: [],
      extension_range: [],
      extension: [],
      options: nil,
      oneof_decl: [
        %Google.Protobuf.OneofDescriptorProto{
          name: "payload",
          options: nil,
          __unknown_fields__: []
        }
      ],
      reserved_range: [],
      reserved_name: [],
      __unknown_fields__: []
    }
  end

  oneof :payload, 0

  field :blob_auth_header, 1,
    type: Disperser.BlobAuthHeader,
    json_name: "blobAuthHeader",
    oneof: 0

  field :disperse_reply, 2,
    type: Disperser.DisperseBlobReply,
    json_name: "disperseReply",
    oneof: 0
end

defmodule Disperser.BlobAuthHeader do
  @moduledoc false

  use Protobuf,
    full_name: "disperser.BlobAuthHeader",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "BlobAuthHeader",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "challenge_parameter",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_UINT32,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "challengeParameter",
          proto3_optional: nil,
          __unknown_fields__: []
        }
      ],
      nested_type: [],
      enum_type: [],
      extension_range: [],
      extension: [],
      options: nil,
      oneof_decl: [],
      reserved_range: [],
      reserved_name: [],
      __unknown_fields__: []
    }
  end

  field :challenge_parameter, 1, type: :uint32, json_name: "challengeParameter"
end

defmodule Disperser.AuthenticationData do
  @moduledoc false

  use Protobuf,
    full_name: "disperser.AuthenticationData",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "AuthenticationData",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "authentication_data",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BYTES,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "authenticationData",
          proto3_optional: nil,
          __unknown_fields__: []
        }
      ],
      nested_type: [],
      enum_type: [],
      extension_range: [],
      extension: [],
      options: nil,
      oneof_decl: [],
      reserved_range: [],
      reserved_name: [],
      __unknown_fields__: []
    }
  end

  field :authentication_data, 1, type: :bytes, json_name: "authenticationData"
end

defmodule Disperser.DisperseBlobRequest do
  @moduledoc false

  use Protobuf,
    full_name: "disperser.DisperseBlobRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "DisperseBlobRequest",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "data",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BYTES,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "data",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "custom_quorum_numbers",
          extendee: nil,
          number: 2,
          label: :LABEL_REPEATED,
          type: :TYPE_UINT32,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "customQuorumNumbers",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "account_id",
          extendee: nil,
          number: 3,
          label: :LABEL_OPTIONAL,
          type: :TYPE_STRING,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "accountId",
          proto3_optional: nil,
          __unknown_fields__: []
        }
      ],
      nested_type: [],
      enum_type: [],
      extension_range: [],
      extension: [],
      options: nil,
      oneof_decl: [],
      reserved_range: [],
      reserved_name: [],
      __unknown_fields__: []
    }
  end

  field :data, 1, type: :bytes
  field :custom_quorum_numbers, 2, repeated: true, type: :uint32, json_name: "customQuorumNumbers"
  field :account_id, 3, type: :string, json_name: "accountId"
end

defmodule Disperser.DisperseBlobReply do
  @moduledoc false

  use Protobuf,
    full_name: "disperser.DisperseBlobReply",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "DisperseBlobReply",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "result",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_ENUM,
          type_name: ".disperser.BlobStatus",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "result",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "request_id",
          extendee: nil,
          number: 2,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BYTES,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "requestId",
          proto3_optional: nil,
          __unknown_fields__: []
        }
      ],
      nested_type: [],
      enum_type: [],
      extension_range: [],
      extension: [],
      options: nil,
      oneof_decl: [],
      reserved_range: [],
      reserved_name: [],
      __unknown_fields__: []
    }
  end

  field :result, 1, type: Disperser.BlobStatus, enum: true
  field :request_id, 2, type: :bytes, json_name: "requestId"
end

defmodule Disperser.BlobStatusRequest do
  @moduledoc false

  use Protobuf,
    full_name: "disperser.BlobStatusRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "BlobStatusRequest",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "request_id",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BYTES,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "requestId",
          proto3_optional: nil,
          __unknown_fields__: []
        }
      ],
      nested_type: [],
      enum_type: [],
      extension_range: [],
      extension: [],
      options: nil,
      oneof_decl: [],
      reserved_range: [],
      reserved_name: [],
      __unknown_fields__: []
    }
  end

  field :request_id, 1, type: :bytes, json_name: "requestId"
end

defmodule Disperser.BlobStatusReply do
  @moduledoc false

  use Protobuf,
    full_name: "disperser.BlobStatusReply",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "BlobStatusReply",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "status",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_ENUM,
          type_name: ".disperser.BlobStatus",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "status",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "info",
          extendee: nil,
          number: 2,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".disperser.BlobInfo",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "info",
          proto3_optional: nil,
          __unknown_fields__: []
        }
      ],
      nested_type: [],
      enum_type: [],
      extension_range: [],
      extension: [],
      options: nil,
      oneof_decl: [],
      reserved_range: [],
      reserved_name: [],
      __unknown_fields__: []
    }
  end

  field :status, 1, type: Disperser.BlobStatus, enum: true
  field :info, 2, type: Disperser.BlobInfo
end

defmodule Disperser.RetrieveBlobRequest do
  @moduledoc false

  use Protobuf,
    full_name: "disperser.RetrieveBlobRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "RetrieveBlobRequest",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "batch_header_hash",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BYTES,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "batchHeaderHash",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "blob_index",
          extendee: nil,
          number: 2,
          label: :LABEL_OPTIONAL,
          type: :TYPE_UINT32,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "blobIndex",
          proto3_optional: nil,
          __unknown_fields__: []
        }
      ],
      nested_type: [],
      enum_type: [],
      extension_range: [],
      extension: [],
      options: nil,
      oneof_decl: [],
      reserved_range: [],
      reserved_name: [],
      __unknown_fields__: []
    }
  end

  field :batch_header_hash, 1, type: :bytes, json_name: "batchHeaderHash"
  field :blob_index, 2, type: :uint32, json_name: "blobIndex"
end

defmodule Disperser.RetrieveBlobReply do
  @moduledoc false

  use Protobuf,
    full_name: "disperser.RetrieveBlobReply",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "RetrieveBlobReply",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "data",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BYTES,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "data",
          proto3_optional: nil,
          __unknown_fields__: []
        }
      ],
      nested_type: [],
      enum_type: [],
      extension_range: [],
      extension: [],
      options: nil,
      oneof_decl: [],
      reserved_range: [],
      reserved_name: [],
      __unknown_fields__: []
    }
  end

  field :data, 1, type: :bytes
end

defmodule Disperser.BlobInfo do
  @moduledoc false

  use Protobuf,
    full_name: "disperser.BlobInfo",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "BlobInfo",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "blob_header",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".disperser.BlobHeader",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "blobHeader",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "blob_verification_proof",
          extendee: nil,
          number: 2,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".disperser.BlobVerificationProof",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "blobVerificationProof",
          proto3_optional: nil,
          __unknown_fields__: []
        }
      ],
      nested_type: [],
      enum_type: [],
      extension_range: [],
      extension: [],
      options: nil,
      oneof_decl: [],
      reserved_range: [],
      reserved_name: [],
      __unknown_fields__: []
    }
  end

  field :blob_header, 1, type: Disperser.BlobHeader, json_name: "blobHeader"

  field :blob_verification_proof, 2,
    type: Disperser.BlobVerificationProof,
    json_name: "blobVerificationProof"
end

defmodule Disperser.BlobHeader do
  @moduledoc false

  use Protobuf,
    full_name: "disperser.BlobHeader",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "BlobHeader",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "commitment",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".common.G1Commitment",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "commitment",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "data_length",
          extendee: nil,
          number: 2,
          label: :LABEL_OPTIONAL,
          type: :TYPE_UINT32,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "dataLength",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "blob_quorum_params",
          extendee: nil,
          number: 3,
          label: :LABEL_REPEATED,
          type: :TYPE_MESSAGE,
          type_name: ".disperser.BlobQuorumParam",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "blobQuorumParams",
          proto3_optional: nil,
          __unknown_fields__: []
        }
      ],
      nested_type: [],
      enum_type: [],
      extension_range: [],
      extension: [],
      options: nil,
      oneof_decl: [],
      reserved_range: [],
      reserved_name: [],
      __unknown_fields__: []
    }
  end

  field :commitment, 1, type: Common.G1Commitment
  field :data_length, 2, type: :uint32, json_name: "dataLength"

  field :blob_quorum_params, 3,
    repeated: true,
    type: Disperser.BlobQuorumParam,
    json_name: "blobQuorumParams"
end

defmodule Disperser.BlobQuorumParam do
  @moduledoc false

  use Protobuf,
    full_name: "disperser.BlobQuorumParam",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "BlobQuorumParam",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "quorum_number",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_UINT32,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "quorumNumber",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "adversary_threshold_percentage",
          extendee: nil,
          number: 2,
          label: :LABEL_OPTIONAL,
          type: :TYPE_UINT32,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "adversaryThresholdPercentage",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "confirmation_threshold_percentage",
          extendee: nil,
          number: 3,
          label: :LABEL_OPTIONAL,
          type: :TYPE_UINT32,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "confirmationThresholdPercentage",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "chunk_length",
          extendee: nil,
          number: 4,
          label: :LABEL_OPTIONAL,
          type: :TYPE_UINT32,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "chunkLength",
          proto3_optional: nil,
          __unknown_fields__: []
        }
      ],
      nested_type: [],
      enum_type: [],
      extension_range: [],
      extension: [],
      options: nil,
      oneof_decl: [],
      reserved_range: [],
      reserved_name: [],
      __unknown_fields__: []
    }
  end

  field :quorum_number, 1, type: :uint32, json_name: "quorumNumber"

  field :adversary_threshold_percentage, 2,
    type: :uint32,
    json_name: "adversaryThresholdPercentage"

  field :confirmation_threshold_percentage, 3,
    type: :uint32,
    json_name: "confirmationThresholdPercentage"

  field :chunk_length, 4, type: :uint32, json_name: "chunkLength"
end

defmodule Disperser.BlobVerificationProof do
  @moduledoc false

  use Protobuf,
    full_name: "disperser.BlobVerificationProof",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "BlobVerificationProof",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "batch_id",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_UINT32,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "batchId",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "blob_index",
          extendee: nil,
          number: 2,
          label: :LABEL_OPTIONAL,
          type: :TYPE_UINT32,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "blobIndex",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "batch_metadata",
          extendee: nil,
          number: 3,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".disperser.BatchMetadata",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "batchMetadata",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "inclusion_proof",
          extendee: nil,
          number: 4,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BYTES,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "inclusionProof",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "quorum_indexes",
          extendee: nil,
          number: 5,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BYTES,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "quorumIndexes",
          proto3_optional: nil,
          __unknown_fields__: []
        }
      ],
      nested_type: [],
      enum_type: [],
      extension_range: [],
      extension: [],
      options: nil,
      oneof_decl: [],
      reserved_range: [],
      reserved_name: [],
      __unknown_fields__: []
    }
  end

  field :batch_id, 1, type: :uint32, json_name: "batchId"
  field :blob_index, 2, type: :uint32, json_name: "blobIndex"
  field :batch_metadata, 3, type: Disperser.BatchMetadata, json_name: "batchMetadata"
  field :inclusion_proof, 4, type: :bytes, json_name: "inclusionProof"
  field :quorum_indexes, 5, type: :bytes, json_name: "quorumIndexes"
end

defmodule Disperser.BatchMetadata do
  @moduledoc false

  use Protobuf,
    full_name: "disperser.BatchMetadata",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "BatchMetadata",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "batch_header",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".disperser.BatchHeader",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "batchHeader",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "signatory_record_hash",
          extendee: nil,
          number: 2,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BYTES,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "signatoryRecordHash",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "fee",
          extendee: nil,
          number: 3,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BYTES,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "fee",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "confirmation_block_number",
          extendee: nil,
          number: 4,
          label: :LABEL_OPTIONAL,
          type: :TYPE_UINT32,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "confirmationBlockNumber",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "batch_header_hash",
          extendee: nil,
          number: 5,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BYTES,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "batchHeaderHash",
          proto3_optional: nil,
          __unknown_fields__: []
        }
      ],
      nested_type: [],
      enum_type: [],
      extension_range: [],
      extension: [],
      options: nil,
      oneof_decl: [],
      reserved_range: [],
      reserved_name: [],
      __unknown_fields__: []
    }
  end

  field :batch_header, 1, type: Disperser.BatchHeader, json_name: "batchHeader"
  field :signatory_record_hash, 2, type: :bytes, json_name: "signatoryRecordHash"
  field :fee, 3, type: :bytes
  field :confirmation_block_number, 4, type: :uint32, json_name: "confirmationBlockNumber"
  field :batch_header_hash, 5, type: :bytes, json_name: "batchHeaderHash"
end

defmodule Disperser.BatchHeader do
  @moduledoc false

  use Protobuf,
    full_name: "disperser.BatchHeader",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "BatchHeader",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "batch_root",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BYTES,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "batchRoot",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "quorum_numbers",
          extendee: nil,
          number: 2,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BYTES,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "quorumNumbers",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "quorum_signed_percentages",
          extendee: nil,
          number: 3,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BYTES,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "quorumSignedPercentages",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "reference_block_number",
          extendee: nil,
          number: 4,
          label: :LABEL_OPTIONAL,
          type: :TYPE_UINT32,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "referenceBlockNumber",
          proto3_optional: nil,
          __unknown_fields__: []
        }
      ],
      nested_type: [],
      enum_type: [],
      extension_range: [],
      extension: [],
      options: nil,
      oneof_decl: [],
      reserved_range: [],
      reserved_name: [],
      __unknown_fields__: []
    }
  end

  field :batch_root, 1, type: :bytes, json_name: "batchRoot"
  field :quorum_numbers, 2, type: :bytes, json_name: "quorumNumbers"
  field :quorum_signed_percentages, 3, type: :bytes, json_name: "quorumSignedPercentages"
  field :reference_block_number, 4, type: :uint32, json_name: "referenceBlockNumber"
end

defmodule Disperser.Disperser.Service do
  @moduledoc false

  use GRPC.Service, name: "disperser.Disperser", protoc_gen_elixir_version: "0.16.0"

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.ServiceDescriptorProto{
      name: "Disperser",
      method: [
        %Google.Protobuf.MethodDescriptorProto{
          name: "DisperseBlob",
          input_type: ".disperser.DisperseBlobRequest",
          output_type: ".disperser.DisperseBlobReply",
          options: %Google.Protobuf.MethodOptions{
            deprecated: false,
            idempotency_level: :IDEMPOTENCY_UNKNOWN,
            features: nil,
            uninterpreted_option: [],
            __pb_extensions__: %{},
            __unknown_fields__: []
          },
          client_streaming: false,
          server_streaming: false,
          __unknown_fields__: []
        },
        %Google.Protobuf.MethodDescriptorProto{
          name: "DisperseBlobAuthenticated",
          input_type: ".disperser.AuthenticatedRequest",
          output_type: ".disperser.AuthenticatedReply",
          options: nil,
          client_streaming: true,
          server_streaming: true,
          __unknown_fields__: []
        },
        %Google.Protobuf.MethodDescriptorProto{
          name: "GetBlobStatus",
          input_type: ".disperser.BlobStatusRequest",
          output_type: ".disperser.BlobStatusReply",
          options: %Google.Protobuf.MethodOptions{
            deprecated: false,
            idempotency_level: :IDEMPOTENCY_UNKNOWN,
            features: nil,
            uninterpreted_option: [],
            __pb_extensions__: %{},
            __unknown_fields__: []
          },
          client_streaming: false,
          server_streaming: false,
          __unknown_fields__: []
        },
        %Google.Protobuf.MethodDescriptorProto{
          name: "RetrieveBlob",
          input_type: ".disperser.RetrieveBlobRequest",
          output_type: ".disperser.RetrieveBlobReply",
          options: %Google.Protobuf.MethodOptions{
            deprecated: false,
            idempotency_level: :IDEMPOTENCY_UNKNOWN,
            features: nil,
            uninterpreted_option: [],
            __pb_extensions__: %{},
            __unknown_fields__: []
          },
          client_streaming: false,
          server_streaming: false,
          __unknown_fields__: []
        }
      ],
      options: nil,
      __unknown_fields__: []
    }
  end

  rpc :DisperseBlob, Disperser.DisperseBlobRequest, Disperser.DisperseBlobReply

  rpc :DisperseBlobAuthenticated,
      stream(Disperser.AuthenticatedRequest),
      stream(Disperser.AuthenticatedReply)

  rpc :GetBlobStatus, Disperser.BlobStatusRequest, Disperser.BlobStatusReply

  rpc :RetrieveBlob, Disperser.RetrieveBlobRequest, Disperser.RetrieveBlobReply
end

defmodule Disperser.Disperser.Stub do
  @moduledoc false

  use GRPC.Stub, service: Disperser.Disperser.Service
end
