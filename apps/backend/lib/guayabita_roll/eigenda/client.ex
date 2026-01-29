defmodule GuayabitaRoll.EigenDA.Client do
  @moduledoc """
  EigenDA V2 Client using Go signer for production use.
  
  This module provides a clean Elixir API that delegates to the Go signer
  for actual EigenDA interactions.
  
  ## Usage
  
      alias GuayabitaRoll.EigenDA.Client
      
      # Disperse a blob
      {:ok, blob_key} = Client.disperse_blob("Hello World")
      
      # Get blob status
      {:ok, :complete} = Client.get_blob_status(blob_key)
  
  ## Configuration
  
  Set the following environment variable:
  
      export EIGENDA_PRIVATE_KEY=0x...
  
  """
  
  alias GuayabitaRoll.EigenDA.GoSigner
  require Logger

  @doc """
  Disperses a blob to EigenDA using the Go signer.
  
  ## Parameters
  - data: Binary data to disperse
  
  ## Returns
  - {:ok, blob_key} on success
  - {:error, reason} on failure
  """
  def disperse_blob(data) when is_binary(data) do
    private_key = get_private_key()
    
    case GoSigner.disperse_blob(data, private_key) do
      {:ok, blob_key} ->
        Logger.info("[EigenDA] Blob dispersed successfully. Key: #{Base.encode16(blob_key)}")
        {:ok, blob_key}
        
      {:error, reason} ->
        Logger.error("[EigenDA] Failed to disperse blob: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Gets the status of a dispersed blob.
  
  ## Parameters
  - blob_key: Binary blob key returned from disperse_blob/1
  
  ## Returns
  - {:ok, :complete} when blob is confirmed
  - {:error, reason} on failure
  """
  def get_blob_status(blob_key) when is_binary(blob_key) do
    private_key = get_private_key()
    
    case GoSigner.get_blob_status(blob_key, private_key) do
      {:ok, :complete} ->
        {:ok, :complete}
        
      {:error, reason} ->
        Logger.error("[EigenDA] Failed to get blob status: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Private functions

  defp get_private_key do
    case System.get_env("EIGENDA_PRIVATE_KEY") do
      nil ->
        raise "EIGENDA_PRIVATE_KEY environment variable not set"
        
      key ->
        key
    end
  end
end
