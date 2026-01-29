defmodule GuayabitaRoll.EigenDA.MockClient do
  @moduledoc """
  Mock client for EigenDA V2 used in tests.
  Returns predictable values for testing purposes.
  """
  
  def disperse_blob(_data) do
    # Simulate a successful disperse by returning a fake blob_key (32 bytes)
    {:ok, :crypto.strong_rand_bytes(32)}
  end
  
  def get_blob_status(_blob_key) do
    # Simulate COMPLETE status (V2 API)
    # V2 Enums: UNKNOWN(0), QUEUED(1), ENCODED(2), GATHERING_SIGNATURES(3), COMPLETE(4), FAILED(5)
    {:ok, %{
      status: :COMPLETE,
      blob_inclusion_info: %{
        blob_certificate: %{},
        blob_index: 0,
        inclusion_proof: <<>>
      }
    }}
  end
end
