defmodule GuayabitaRoll.EntropyTest do
  use ExUnit.Case, async: true

  alias GuayabitaRoll.Entropy

  describe "generate_seed_pair/0" do
    test "returns hex seed and hash with correct format" do
      %{seed: seed, hash: hash} = Entropy.generate_seed_pair()

      assert is_binary(seed)
      assert is_binary(hash)
      assert String.length(seed) == 64
      assert String.length(hash) == 64
      assert seed =~ ~r/\A[0-9a-f]{64}\z/
      assert hash =~ ~r/\A[0-9a-f]{64}\z/
    end

    test "generates unique seeds on each call" do
      pair1 = Entropy.generate_seed_pair()
      pair2 = Entropy.generate_seed_pair()

      assert pair1.seed != pair2.seed
      assert pair1.hash != pair2.hash
    end

    test "hash is Keccak256 of seed" do
      %{seed: seed, hash: hash} = Entropy.generate_seed_pair()

      seed_binary = Base.decode16!(seed, case: :lower)
      expected_hash = ExKeccak.hash_256(seed_binary) |> Base.encode16(case: :lower)

      assert hash == expected_hash
    end
  end

  describe "build_batch/1" do
    test "builds a merkle tree from a list of hashes" do
      hashes = generate_test_hashes(4)
      tree = Entropy.build_batch(hashes)

      assert %MerkleTree{} = tree
      assert tree.root != nil
      assert length(tree.blocks) == 4
    end

    test "builds tree with power of 2 elements" do
      for count <- [2, 4, 8] do
        hashes = generate_test_hashes(count)
        tree = Entropy.build_batch(hashes)

        assert %MerkleTree{} = tree
        assert length(tree.blocks) == count
      end
    end

    test "raises error with non-power of 2 elements" do
      hashes = generate_test_hashes(3)

      # MerkleTree.new/2 requires power of 2 elements
      assert_raise MerkleTree.ArgumentError, fn ->
        Entropy.build_batch(hashes)
      end
    end
  end

  describe "generate_proof/2" do
    test "generates proof for valid index" do
      hashes = generate_test_hashes(4)
      tree = Entropy.build_batch(hashes)

      proof = Entropy.generate_proof(tree, 0)

      assert is_list(proof)
      # For 4 elements, tree height is 2, so proof should have 2 sibling hashes
      assert length(proof) == 2
    end

    test "generates different proofs for different indices" do
      hashes = generate_test_hashes(4)
      tree = Entropy.build_batch(hashes)

      proof0 = Entropy.generate_proof(tree, 0)
      _proof1 = Entropy.generate_proof(tree, 1)
      proof2 = Entropy.generate_proof(tree, 2)

      # Proofs should differ (at least in sibling order)
      assert proof0 != proof2
    end
  end

  describe "generate_proof_by_hash/2" do
    test "finds hash and returns proof with index" do
      hashes = generate_test_hashes(4)
      tree = Entropy.build_batch(hashes)
      target_hash = Enum.at(hashes, 2)

      assert {:ok, proof, index} = Entropy.generate_proof_by_hash(tree, target_hash)
      assert index == 2
      assert is_list(proof)
      assert length(proof) == 2
    end

    test "returns error for non-existent hash" do
      hashes = generate_test_hashes(4)
      tree = Entropy.build_batch(hashes)
      fake_hash = String.duplicate("ab", 32)

      assert {:error, :not_found} = Entropy.generate_proof_by_hash(tree, fake_hash)
    end
  end

  describe "verify_proof/4" do
    test "verifies valid proof returns true" do
      pairs = for _ <- 1..4, do: Entropy.generate_seed_pair()
      hashes = Enum.map(pairs, & &1.hash)
      tree = Entropy.build_batch(hashes)

      # Get proof for index 1
      {:ok, proof, index} = Entropy.generate_proof_by_hash(tree, Enum.at(hashes, 1))
      root_hash = Entropy.root_hash(tree)  # Already returns hex string
      block = Enum.at(hashes, 1)

      assert Entropy.verify_proof(block, index, root_hash, proof) == true
    end

    test "rejects invalid proof" do
      pairs = for _ <- 1..4, do: Entropy.generate_seed_pair()
      hashes = Enum.map(pairs, & &1.hash)
      tree = Entropy.build_batch(hashes)

      {:ok, proof, _index} = Entropy.generate_proof_by_hash(tree, Enum.at(hashes, 1))
      root_hash = Entropy.root_hash(tree)  # Already returns hex string

      # Try to verify with wrong block (index 0 instead of 1)
      wrong_block = Enum.at(hashes, 0)

      assert Entropy.verify_proof(wrong_block, 1, root_hash, proof) == false
    end

    test "rejects proof with wrong index" do
      pairs = for _ <- 1..4, do: Entropy.generate_seed_pair()
      hashes = Enum.map(pairs, & &1.hash)
      tree = Entropy.build_batch(hashes)

      {:ok, proof, _index} = Entropy.generate_proof_by_hash(tree, Enum.at(hashes, 1))
      root_hash = Entropy.root_hash(tree)  # Already returns hex string
      block = Enum.at(hashes, 1)

      # Verify with wrong index
      assert Entropy.verify_proof(block, 0, root_hash, proof) == false
    end
  end

  describe "root_hash/1" do
    test "returns the root hash of the tree" do
      hashes = generate_test_hashes(4)
      tree = Entropy.build_batch(hashes)

      root = Entropy.root_hash(tree)

      assert is_binary(root)
      # Root hash should be 64 char hex string (32 bytes encoded)
      assert String.length(root) == 64
      assert root =~ ~r/\A[0-9a-f]{64}\z/
    end

    test "same inputs produce same root hash" do
      hashes = generate_test_hashes(4)

      tree1 = Entropy.build_batch(hashes)
      tree2 = Entropy.build_batch(hashes)

      assert Entropy.root_hash(tree1) == Entropy.root_hash(tree2)
    end

    test "different inputs produce different root hash" do
      hashes1 = generate_test_hashes(4)
      hashes2 = generate_test_hashes(4)

      tree1 = Entropy.build_batch(hashes1)
      tree2 = Entropy.build_batch(hashes2)

      assert Entropy.root_hash(tree1) != Entropy.root_hash(tree2)
    end
  end

  # Helper function to generate test hashes
  defp generate_test_hashes(count) do
    for _ <- 1..count do
      :crypto.strong_rand_bytes(32)
      |> ExKeccak.hash_256()
      |> Base.encode16(case: :lower)
    end
  end
end
