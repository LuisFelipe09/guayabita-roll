defmodule GuayabitaRoll.EigenDA.MockClient do
  @moduledoc """
  Mock client for EigenDA used in tests.
  Returns predictable values for testing purposes.
  """
  
  def disperse_blob(_data) do
    # Simulate a successful disperse by returning a fake request_id
    {:ok, :crypto.strong_rand_bytes(32)}
  end
  
  def get_blob_status(_request_id) do
    # Simulate immediate confirmation (for testing)
    {:ok, %{status: :CONFIRMED, blob_info: %{}}}
  end
end
