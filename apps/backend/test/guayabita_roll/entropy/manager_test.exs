defmodule GuayabitaRoll.Entropy.ManagerTest do
  use GuayabitaRoll.DataCase, async: false

  alias GuayabitaRoll.Entropy.Manager

  describe "create_batch/1" do
    test "creates a batch with default size (1024 seeds)" do
      {:ok, batch} = Manager.create_batch()

      assert batch.size == 1024
      assert batch.status == "pending"
      assert batch.merkle_root =~ ~r/\A[0-9a-f]{64}\z/
      assert length(batch.seeds) == 1024
    end

    test "creates a batch with custom size (power of 2)" do
      {:ok, batch} = Manager.create_batch(128)

      assert batch.size == 128
      assert length(batch.seeds) == 128
    end

    test "all seeds have correct format" do
      {:ok, batch} = Manager.create_batch(16)

      for seed <- batch.seeds do
        assert seed.seed =~ ~r/\A[0-9a-f]{64}\z/
        assert seed.hash =~ ~r/\A[0-9a-f]{64}\z/
        assert seed.status == "available"
        assert seed.batch_id == batch.id
      end
    end

    test "seeds have sequential indices" do
      {:ok, batch} = Manager.create_batch(16)

      indices = batch.seeds |> Enum.map(& &1.index) |> Enum.sort()
      assert indices == Enum.to_list(0..15)
    end

    test "raises error with non-power of 2 size" do
      assert_raise MerkleTree.ArgumentError, fn ->
        Manager.create_batch(100)
      end
    end
  end

  describe "get_any_available_seed/0" do
    test "returns available seed and reserves it" do
      {:ok, _batch} = Manager.create_batch(16)

      {:ok, seed} = Manager.get_any_available_seed()

      assert seed.status == "reserved"
      assert seed.seed =~ ~r/\A[0-9a-f]{64}\z/
    end

    test "returns error when no seeds available" do
      # No batches created
      assert {:error, :no_seeds_available} = Manager.get_any_available_seed()
    end

    test "does not return same seed twice" do
      {:ok, _batch} = Manager.create_batch(16)

      {:ok, seed1} = Manager.get_any_available_seed()
      {:ok, seed2} = Manager.get_any_available_seed()

      refute seed1.id == seed2.id
    end
  end

  describe "get_available_seed/0" do
    test "returns error when batch is not published" do
      {:ok, _batch} = Manager.create_batch(16)

      # Batch is "pending", not "published"
      assert {:error, :no_seeds_available} = Manager.get_available_seed()
    end

    test "returns seed when batch is published" do
      {:ok, batch} = Manager.create_batch(16)
      {:ok, _published_batch} = Manager.publish_batch(batch, "test_blob_id")

      {:ok, seed} = Manager.get_available_seed()

      assert seed.status == "reserved"
    end
  end

  describe "use_seed/2" do
    test "marks seed as used with game_id" do
      {:ok, _batch} = Manager.create_batch(16)
      {:ok, seed} = Manager.get_any_available_seed()

      game_id = Ecto.UUID.generate()
      {:ok, used_seed} = Manager.use_seed(seed, game_id)

      assert used_seed.status == "used"
      assert used_seed.game_id == game_id
      assert used_seed.used_at != nil
    end
  end

  describe "publish_batch/2" do
    test "updates batch status and blob_id" do
      {:ok, batch} = Manager.create_batch(16)

      {:ok, published} = Manager.publish_batch(batch, "eigenda_blob_123")

      assert published.status == "published"
      assert published.eigenda_blob_id == "eigenda_blob_123"
      assert published.published_at != nil
    end
  end

  describe "generate_proof_for_seed/1" do
    test "generates valid merkle proof" do
      {:ok, _batch} = Manager.create_batch(16)
      {:ok, seed} = Manager.get_any_available_seed()

      {:ok, proof_data} = Manager.generate_proof_for_seed(seed)

      assert proof_data.seed == seed.seed
      assert proof_data.hash == seed.hash
      assert proof_data.index == seed.index
      assert proof_data.merkle_root =~ ~r/\A[0-9a-f]{64}\z/
      # Proof is a list of binary sibling hashes (4 levels for 16 elements)
      assert is_list(proof_data.proof)
      assert length(proof_data.proof) == 4
    end
  end

  describe "available_seeds_count/0" do
    test "counts seeds in published batches only" do
      {:ok, _pending_batch} = Manager.create_batch(16)
      {:ok, published_batch} = Manager.create_batch(32)
      Manager.publish_batch(published_batch, "blob_id")

      count = Manager.available_seeds_count()

      assert count == 32
    end
  end

  describe "total_available_seeds_count/0" do
    test "counts all available seeds regardless of batch status" do
      {:ok, _batch1} = Manager.create_batch(16)
      {:ok, _batch2} = Manager.create_batch(32)

      count = Manager.total_available_seeds_count()

      assert count == 48
    end
  end

  describe "list_batches/0" do
    test "lists batches with seed counts" do
      {:ok, batch} = Manager.create_batch(16)
      {:ok, seed} = Manager.get_any_available_seed()
      Manager.use_seed(seed, Ecto.UUID.generate())

      [result] = Manager.list_batches()

      assert result.batch.id == batch.id
      assert result.total_seeds == 16
      # 1 seed was reserved (get_any_available_seed), then used (use_seed)
      # So available = 15, used = 1
      assert result.available_seeds == 15
      assert result.used_seeds == 1
    end
  end

  describe "end-to-end merkle proof verification" do
    test "generated proof can be verified against the batch merkle root" do
      alias GuayabitaRoll.Entropy

      # 1. Crear un batch
      {:ok, _batch} = Manager.create_batch(16)
      
      # 2. Obtener una semilla
      {:ok, seed} = Manager.get_any_available_seed()
      
      # 3. Generar la prueba
      {:ok, proof_data} = Manager.generate_proof_for_seed(seed)
      
      # 4. VERIFICAR que la prueba es correcta usando el módulo Entropy
      is_valid = Entropy.verify_proof(
        proof_data.hash,
        proof_data.index,
        proof_data.merkle_root,
        proof_data.proof
      )
      
      assert is_valid == true
    end

    test "proof fails verification with wrong hash" do
      alias GuayabitaRoll.Entropy

      {:ok, _batch} = Manager.create_batch(16)
      {:ok, seed} = Manager.get_any_available_seed()
      {:ok, proof_data} = Manager.generate_proof_for_seed(seed)
      
      # Intentar verificar con un hash incorrecto
      wrong_hash = String.duplicate("ab", 32)
      
      is_valid = Entropy.verify_proof(
        wrong_hash,
        proof_data.index,
        proof_data.merkle_root,
        proof_data.proof
      )
      
      assert is_valid == false
    end

    test "proof fails verification with wrong index" do
      alias GuayabitaRoll.Entropy

      {:ok, _batch} = Manager.create_batch(16)
      {:ok, seed} = Manager.get_any_available_seed()
      {:ok, proof_data} = Manager.generate_proof_for_seed(seed)
      
      # Intentar verificar con un índice incorrecto
      wrong_index = rem(proof_data.index + 1, 16)
      
      is_valid = Entropy.verify_proof(
        proof_data.hash,
        wrong_index,
        proof_data.merkle_root,
        proof_data.proof
      )
      
      assert is_valid == false
    end
  end
end
