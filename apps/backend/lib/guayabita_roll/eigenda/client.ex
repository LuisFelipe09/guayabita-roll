defmodule GuayabitaRoll.EigenDA.Client do
  @moduledoc """
  Cliente gRPC para interactuar con EigenDA Disperser.
  
  Holesky Testnet: disperser-holesky.eigenda.xyz:443
  """
  
  require Logger
  alias Disperser.Disperser.Stub
  alias Disperser.{DisperseBlobRequest, BlobStatusRequest}

  # Configuración por defecto (Holesky Testnet)
  @endpoint "disperser-holesky.eigenda.xyz:443"

  @doc """
  Envía un blob al Disperser de EigenDA.
  """
  def disperse_blob(data) when is_binary(data) do
    with {:ok, channel} <- GRPC.Stub.connect(@endpoint, ssl: true) do
      request = %DisperseBlobRequest{data: data}
      
      try do
        case Stub.disperse_blob(channel, request) do
          {:ok, reply} ->
            Logger.info("[EigenDA] Blob recibido. Request ID: #{Base.encode16(reply.request_id)}")
            {:ok, reply.request_id}
            
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
  def get_blob_status(request_id) when is_binary(request_id) do
    with {:ok, channel} <- GRPC.Stub.connect(@endpoint, ssl: true) do
      try do
        poll_status(channel, request_id)
      after
        GRPC.Stub.disconnect(channel)
      end
    end
  end

  defp poll_status(channel, request_id, attempts \\ 0) do
    # Máximo 20 intentos (~10 minutos si esperamos 30s)
    if attempts > 20 do
      {:error, :timeout}
    else
      request = %BlobStatusRequest{request_id: request_id}
      
      case Stub.get_blob_status(channel, request) do
        {:ok, reply} ->
          handle_status_reply(reply, channel, request_id, attempts)
          
        {:error, reason} ->
          Logger.error("[EigenDA] Error consultando status: #{inspect(reason)}")
          {:error, reason}
      end
    end
  end

  defp handle_status_reply(reply, channel, request_id, attempts) do
    status = reply.status
    
    case status do
      :CONFIRMED ->
        Logger.info("[EigenDA] Blob CONFIRMADO")
        {:ok, reply.info}
        
      :FINALIZED ->
        Logger.info("[EigenDA] Blob FINALIZADO")
        {:ok, reply.info}
        
      :FAILED ->
        Logger.error("[EigenDA] Blob FALLÓ")
        {:error, :failed}
        
      :INSUFFICIENT_SIGNATURES ->
        Logger.error("[EigenDA] Firmas insuficientes")
        {:error, :insufficient_signatures}
        
      _other ->
        # PROCESSING o DISPERSING: esperamos y reintentamos
        Logger.debug("[EigenDA] Status actual: #{inspect(status)}. Reintentando...")
        Process.sleep(15_000) # Esperar 15 segundos
        poll_status(channel, request_id, attempts + 1)
    end
  end
end
