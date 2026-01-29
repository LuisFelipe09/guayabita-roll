defmodule GuayabitaRoll.EigenDA.GoSigner do
  @moduledoc """
  Wrapper around the Go EigenDA signer.
  Communicates with the Go binary via Port (stdin/stdout with JSON).
  """

  require Logger

  # Use absolute path for now
  @go_binary_path "/Users/felipe/Documents/software_propio/guayabita-roll/backend/priv/eigenda-signer"

  @doc """
  Disperses a blob to EigenDA using the Go client.
  
  ## Parameters
  - data: Binary data to disperse
  - private_key: Hex-encoded private key (with or without 0x prefix)
  
  ## Returns
  - {:ok, blob_key} on success
  - {:error, reason} on failure
  """
  def disperse_blob(data, private_key) when is_binary(data) do
    request = %{
      action: "disperse_blob",
      data: Base.encode16(data, case: :lower)
    }
    
    case call_go_signer(request, private_key) do
      {:ok, %{"success" => true, "blob_key" => blob_key}} ->
        {:ok, Base.decode16!(blob_key, case: :mixed)}
        
      {:ok, %{"success" => false, "error" => error}} ->
        {:error, error}
        
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Gets the status of a blob from EigenDA.
  
  ## Parameters
  - blob_key: Binary blob key
  - private_key: Hex-encoded private key
  
  ## Returns
  - {:ok, status} on success
  - {:error, reason} on failure
  """
  def get_blob_status(blob_key, private_key) when is_binary(blob_key) do
    request = %{
      action: "get_blob_status",
      data: Base.encode16(blob_key, case: :lower)
    }
    
    case call_go_signer(request, private_key) do
      {:ok, %{"success" => true}} ->
        {:ok, :complete}
        
      {:ok, %{"success" => false, "error" => error}} ->
        {:error, error}
        
      {:error, reason} ->
        {:error, reason}
    end
  end

  # Private functions

  defp clean_private_key(pk) do
    pk
    |> String.trim()
    |> String.replace_prefix("0x", "")
  end

  defp call_go_signer(request, private_key) do
    json_request = Jason.encode!(request) <> "\n"
    
    Logger.debug("[GoSigner] Calling Go signer with action: #{request.action}")
    
    # Set environment variable for the Go process
    # Must be charlists for Port
    clean_key = clean_private_key(private_key)
    env = [{'EIGENDA_PRIVATE_KEY', String.to_charlist(clean_key)}]
    
    port = Port.open({:spawn_executable, @go_binary_path}, [
      :binary,
      :exit_status,
      :use_stdio,
      :stderr_to_stdout,
      {:line, 10000},
      {:env, env}
    ])
    
    # Send request
    Port.command(port, json_request)
    
    # Wait for response
    result = receive_response(port, "")
    
    Port.close(port)
    result
  rescue
    e ->
      Logger.error("[GoSigner] Exception calling Go signer: #{inspect(e)}")
      {:error, "Exception calling Go signer: #{Exception.message(e)}"}
  end
  
  defp receive_response(port, acc) do
    receive do
      {^port, {:data, {:eol, line}}} ->
        # Check if this line is JSON (starts with {)
        trimmed = String.trim(line)
        
        if String.starts_with?(trimmed, "{") do
          # Try to decode it
          case Jason.decode(trimmed) do
            {:ok, %{"success" => _} = response} ->
              # This is our response!
              {:ok, response}
              
            {:ok, _other_json} ->
              # This is some other JSON (debug log), skip it
              receive_response(port, acc)
              
            {:error, _reason} ->
              # Not valid JSON yet, keep accumulating
              receive_response(port, acc <> line <> "\n")
          end
        else
          # This is a debug log line, skip it and continue
          receive_response(port, acc)
        end
        
      {^port, {:data, {:noeol, data}}} ->
        # Accumulate partial data
        receive_response(port, acc <> data)
        
      {^port, {:exit_status, 0}} ->
        # Process exited successfully
        {:ok, %{"success" => true}}
        
      {^port, {:exit_status, exit_code}} ->
        Logger.error("[GoSigner] Go binary exited with code #{exit_code}")
        {:error, "Go signer failed with exit code #{exit_code}"}
    after
      30_000 ->
        {:error, "Timeout calling Go signer"}
    end
  end
end
