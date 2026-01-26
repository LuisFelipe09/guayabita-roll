defmodule GuayabitaRoll.EigenDA.Client do
  @moduledoc """
  Cliente gRPC para interactuar con EigenDA Disperser V2.
  
  Holesky Testnet: disperser-holesky.eigenda.xyz:443
  """
  
  require Logger
  alias Disperser.V2.Disperser.Stub
  alias Disperser.V2.{
    DisperseBlobRequest,
    BlobStatusRequest,
    BlobCommitmentRequest
  }
  alias Common.V2.{BlobHeader, PaymentHeader}
  alias GuayabitaRoll.EigenDA.Utils

  # Configuración por defecto (Holesky Testnet)
  @endpoint "disperser-holesky.eigenda.xyz:443"

  @doc """
  Envía un blob al Disperser de EigenDA V2.
  """
  def disperse_blob(data) when is_binary(data) do
    with {:ok, channel} <- GRPC.Stub.connect(@endpoint, ssl: true) do
      try do
        # 1. Encode Payload (BN254 Field Elements)
        encoded_blob = Utils.encode_payload(data)

        # 2. Get Blob Commitment (RPC)
        {:ok, commitment} = get_blob_commitment(channel, encoded_blob)

        # 3. Construct Blob Header
        header = build_blob_header(encoded_blob, commitment)

        # 4. Sign Blob Header (BlobKey)
        signature = sign_blob_header(header)

        # 5. Send Disperse Request
        request = %DisperseBlobRequest{
          blob: encoded_blob,
          blob_header: header,
          signature: signature,
          # Custom Quorums, Account ID, etc are inside header/request
        }

        case Stub.disperse_blob(channel, request) do
          {:ok, reply} ->
            Logger.info("[EigenDA] Blob recibido. Blob Key: #{Base.encode16(reply.blob_key)}")
            {:ok, reply.blob_key}
            
          {:error, reason} ->
            Logger.error("[EigenDA] Error gRPC en disperse_blob: #{inspect(reason)}")
            {:error, reason}
        end
      after
        GRPC.Stub.disconnect(channel)
      end
    end
  end

  @doc """
  Consulta el estado de un blob hasta que sea CONFIRMED o FINALIZED.
  Retorna la información del certificado de confirmación.
  """
  def get_blob_status(blob_key) when is_binary(blob_key) do
    with {:ok, channel} <- GRPC.Stub.connect(@endpoint, ssl: true) do
      try do
        poll_status(channel, blob_key)
      after
        GRPC.Stub.disconnect(channel)
      end
    end
  end

  # --- Private Helpers ---

  defp get_blob_commitment(channel, blob) do
    request = %BlobCommitmentRequest{blob: blob}
    case Stub.get_blob_commitment(channel, request) do
      {:ok, reply} -> {:ok, reply.blob_commitment}
      {:error, reason} -> {:error, reason}
    end
  end

  defp build_blob_header(_blob, commitment) do
    # Obtener configuración
    account_id = get_config(:account_id)
    # Timestamp en nanosegundos
    timestamp = System.os_time(:nanosecond)

    payment_header = %PaymentHeader{
      account_id: account_id,
      timestamp: timestamp,
      cumulative_payment: <<0>> # Placeholder: On-demand payment logic needed if not reserved
    }

    %BlobHeader{
      version: 1, # BlobParams Version 1? Check Registry. Default to 1.
      quorum_numbers: [0, 1], # ETH and EIGEN quorums
      commitment: commitment,
      payment_header: payment_header
    }
  end

  defp sign_blob_header(header) do
    # 1. Compute Blob Key (Hash)
    blob_key = Utils.compute_blob_key(header)

    # 2. Sign Hash
    raw_pk = get_config(:private_key)
    # Remove 0x prefix if present
    clean_pk = if String.starts_with?(raw_pk, "0x"), do: String.slice(raw_pk, 2..-1//1), else: raw_pk
    private_key = Base.decode16!(clean_pk, case: :mixed)

    # Use ExSecp256k1 to sign
    {:ok, {r, s, v}} = ExSecp256k1.sign(blob_key, private_key)

    # Concatenate r, s, v (recovery id at end? or standard?)
    # Ethereum style: r (32) + s (32) + v (1)
    # v is usually 0 or 1 from ExSecp256k1.
    # Check if we need to add 27? Usually 0/1 for EIP-155 but let's stick to simple

    # NOTE: The library returns {r, s, recovery_id}
    # r and s are binaries. recovery_id is integer.

    # EigenDA typically expects standard EIP-191 signatures or similar.
    # If validation fails, try adding 27 to v (i.e., v + 27).
    <<r::binary, s::binary, v::8>>
  end

  defp poll_status(channel, blob_key, attempts \\ 0) do
    # Máximo 20 intentos (~10 minutos si esperamos 30s)
    if attempts > 20 do
      {:error, :timeout}
    else
      request = %BlobStatusRequest{blob_key: blob_key}
      
      case Stub.get_blob_status(channel, request) do
        {:ok, reply} ->
          handle_status_reply(reply, channel, blob_key, attempts)
          
        {:error, reason} ->
          Logger.error("[EigenDA] Error consultando status: #{inspect(reason)}")
          {:error, reason}
      end
    end
  end

  defp handle_status_reply(reply, channel, blob_key, attempts) do
    status = reply.status
    
    # V2 Enums: UNKNOWN(0), QUEUED(1), ENCODED(2), GATHERING_SIGNATURES(3), COMPLETE(4), FAILED(5)
    # We want COMPLETE (4).

    case status do
      :COMPLETE ->
        Logger.info("[EigenDA] Blob COMPLETADO")
        {:ok, reply.blob_inclusion_info}
        
      :FAILED ->
        Logger.error("[EigenDA] Blob FALLÓ")
        {:error, :failed}
        
      _other ->
        # QUEUED, ENCODED, GATHERING_SIGNATURES: reintentamos
        Logger.debug("[EigenDA] Status actual: #{inspect(status)}. Reintentando...")
        Process.sleep(15_000) # Esperar 15 segundos
        poll_status(channel, blob_key, attempts + 1)
    end
  end

  defp get_config(key) do
    Application.get_env(:backend, :eigenda)[key] || raise "Missing EigenDA config: #{key}"
  end
end
