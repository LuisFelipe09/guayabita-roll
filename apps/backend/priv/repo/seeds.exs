# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# This will generate the initial entropy batches needed for the game.

alias GuayabitaRoll.Entropy.Manager

# Configuración (MerkleTree requires power of 2, so 1024 instead of 1000)
batch_size = System.get_env("SEED_BATCH_SIZE", "1024") |> String.to_integer()
num_batches = System.get_env("SEED_NUM_BATCHES", "1") |> String.to_integer()

IO.puts("🎲 Guayabita Roll - Entropy Seeder")
IO.puts("================================")
IO.puts("Batch size: #{batch_size}")
IO.puts("Number of batches: #{num_batches}")
IO.puts("")

Enum.each(1..num_batches, fn batch_num ->
  IO.write("Creating batch #{batch_num}/#{num_batches}... ")
  
  case Manager.create_batch(batch_size) do
    {:ok, batch} ->
      IO.puts("✅ Created batch #{batch.id}")
      IO.puts("   Merkle Root: #{batch.merkle_root}")
      IO.puts("   Seeds: #{batch.size}")
      IO.puts("")
      
    {:error, reason} ->
      IO.puts("❌ Failed: #{inspect(reason)}")
  end
end)

# Resumen final
total = Manager.total_available_seeds_count()
IO.puts("================================")
IO.puts("✨ Seeding complete!")
IO.puts("   Total available seeds: #{total}")
IO.puts("")
IO.puts("Next steps:")
IO.puts("  1. Publish batches to EigenDA")
IO.puts("  2. Start accepting bets!")
