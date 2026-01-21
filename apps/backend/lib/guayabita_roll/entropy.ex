defmodule GuayabitaRoll.Entropy do
  @moduledoc """
  Módulo de producción para la gestión de azar y compromisos criptográficos.
  """

  @doc """
  Genera una semilla aleatoria y su hash Keccak256 (compatible con Solidity).
  Retorna un mapa con la semilla y el hash en formato hexadecimal.
  """
  def generate_seed_pair do
    # Generamos 32 bytes de entropía criptográficamente segura
    seed_binary = :crypto.strong_rand_bytes(32)

    # Usamos Keccak256 para compatibilidad con Solidity
    hash = ExKeccak.hash_256(seed_binary)

    %{
      seed: Base.encode16(seed_binary, case: :lower),
      hash: Base.encode16(hash, case: :lower)
    }
  end

  @doc """
  Construye el Merkle Tree completo para un lote de semillas.
  Retorna la estructura %MerkleTree{} que incluye los bloques originales y el árbol.

  Los hashes de entrada deben estar en formato hexadecimal lowercase.
  """
  def build_batch(hashes) when is_list(hashes) do
    # Convertimos los hashes hex a binario
    binary_hashes = Enum.map(hashes, &Base.decode16!(&1, case: :lower))

    # Usamos MerkleTree.new/2 para obtener el árbol completo (necesario para prove/2)
    # Keccak256 como función de hashing para compatibilidad con Solidity
    MerkleTree.new(binary_hashes, hash_function: &keccak256/1)
  end

  @doc """
  Genera la prueba de Merkle necesaria para que el Smart Contract valide una semilla.
  Recibe el árbol y el índice (0-based) del elemento a probar.

  Retorna una lista de hashes que conforman la prueba.
  """
  def generate_proof(tree, index) when is_integer(index) do
    MerkleTree.Proof.prove(tree, index)
  end

  @doc """
  Genera la prueba de Merkle buscando el hash en el árbol.
  Retorna {:ok, proof, index} si encuentra el hash, {:error, :not_found} si no.
  """
  def generate_proof_by_hash(tree, target_hash_hex) do
    target_binary = Base.decode16!(target_hash_hex, case: :lower)

    case Enum.find_index(tree.blocks, &(&1 == target_binary)) do
      nil -> {:error, :not_found}
      index -> {:ok, MerkleTree.Proof.prove(tree, index), index}
    end
  end

  @doc """
  Verifica que una prueba sea válida para un bloque dado.
  """
  def verify_proof(block_hex, index, root_hash_hex, proof) do
    block = Base.decode16!(block_hex, case: :lower)
    root_hash = Base.decode16!(root_hash_hex, case: :lower)

    MerkleTree.Proof.proven?({block, index}, root_hash, &keccak256/1, proof)
  end

  @doc """
  Obtiene el root hash del árbol en formato hexadecimal.
  """
  def root_hash(tree) do
    tree.root.value
  end

  # Función helper para Keccak256
  defp keccak256(data), do: ExKeccak.hash_256(data)
end
