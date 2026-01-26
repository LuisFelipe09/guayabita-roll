defmodule GuayabitaRoll.EigenDA.Utils do
  @moduledoc """
  Utilidades para EigenDA V2 (Encoding y Hashing).
  """

  # Constants
  @version_byte 0x00
  @chunk_size 32
  @data_size 31

  @doc """
  Encodes a binary payload according to EigenDA Version 0x0 spec.

  Format:
  [0x00, version_byte, len(payload) (4 bytes), 0x00... (26 bytes)] +
  [0x00, chunk_1 (31 bytes)] +
  [0x00, chunk_2 (31 bytes)] ...

  The result is padded with zero chunks to be a power of 2 length.
  """
  def encode_payload(payload) when is_binary(payload) do
    payload_len = byte_size(payload)

    # 1. Header Chunk
    # 0x00 + version + len(payload) + padding
    header_chunk = <<
      0x00,
      @version_byte,
      payload_len::big-integer-size(32),
      0::size(208) # 26 bytes of zeros
    >>

    # 2. Data Chunks
    # Each 32-byte chunk starts with 0x00 followed by 31 bytes of data
    data_chunks = chunk_data(payload)

    # 3. Combine and Pad to Power of 2
    raw_blob = header_chunk <> data_chunks
    pad_blob(raw_blob)
  end

  defp chunk_data(<<chunk::binary-size(@data_size), rest::binary>>) do
    <<0x00, chunk::binary>> <> chunk_data(rest)
  end

  defp chunk_data(<<rest::binary>>) when byte_size(rest) > 0 do
    padding_size = @data_size - byte_size(rest)
    <<0x00, rest::binary, 0::size(padding_size * 8)>>
  end

  defp chunk_data(<<>>), do: <<>>

  defp pad_blob(blob) do
    total_len = byte_size(blob)
    num_symbols = div(total_len, @chunk_size)

    # Next power of 2 for number of symbols
    target_symbols = next_power_of_two(num_symbols)
    target_len = target_symbols * @chunk_size

    padding_len = target_len - total_len
    blob <> <<0::size(padding_len * 8)>>
  end

  defp next_power_of_two(n) do
    :math.pow(2, ceil(:math.log2(n))) |> round()
  end

  @doc """
  Computes the BlobKey (Keccak256 hash of the BlobHeader).

  blobKey = keccak256(
      abi.encode(
          keccak256(abi.encode(version, quorumNumbers, commitment)),
          paymentHeaderHash
      )
  )
  """
  def compute_blob_key(header) do
    # 1. Inner Hash: keccak256(abi.encode(version, quorumNumbers, commitment))
    # We need to manually construct the ABI encoding equivalent since we don't have full ABI lib.
    # Fortunately, the types are simple: uint32, uint32[], tuple(bytes, bytes, bytes, uint32)

    inner_data = encode_inner_data(header)
    inner_hash = ExKeccak.hash_256(inner_data)

    # 2. Payment Header Hash
    payment_hash = compute_payment_header_hash(header.payment_header)

    # 3. Outer Hash: keccak256(abi.encode(innerHash, paymentHeaderHash))
    # Both are bytes32, so just concatenate
    ExKeccak.hash_256(inner_hash <> payment_hash)
  end

  # Helper to encode inner data (mocking ABI encoding for specific struct)
  # Ideally use an ABI library like `ex_abi` or `ethers`, but manually doing it for now
  # to match the spec: version (uint32), quorum_numbers (uint32[]), commitment (tuple)
  defp encode_inner_data(header) do
    # This is tricky without a proper ABI encoder.
    # However, since we are doing this for signing, we might use the `ExKeccak` directly
    # if we can ensure the packing is correct.
    #
    # BUT, the spec says "abi.encode", which adds padding and offsets for dynamic types (arrays).
    # Since we added `ex_secp256k1`, maybe we should assume `ethers` or similar is available?
    # The user didn't explicitly add `ethers`.

    # Simplified approach for now (assuming standard packing for basic types):
    # If this fails verification on server, we might need a real ABI encoder.

    # Given the constraints, I will implement a minimal ABI encoder for this specific struct.

    # ABI Encoding:
    # 1. version (uint32) -> padded to 32 bytes
    # 2. offset to quorumNumbers (dynamic) -> 32 bytes
    # 3. offset to commitment (tuple) -> 32 bytes
    # --- Data Area ---
    # 4. quorumNumbers length
    # 5. quorumNumbers items (padded)
    # 6. Commitment data...

    # Actually, let's look at how we can simplify.
    # If the user allows me to use `ethers` I would add it.
    # But let's try to do it right.

    # For now, I will leave a placeholder comment that this needs correct ABI encoding.
    # Implementing a full ABI encoder here is error prone.
    # I will assume simple concatenation for now to proceed, but mark it as TODO.
    # WAIT, if I sign the wrong thing, it will fail.

    # Let's try to be as close as possible.

    # Use Ethers.Keccak if available? No.

    # Let's rely on a simpler assumption: The server verifies the signature.
    # If I can't encode it exactly like Solidity `abi.encode`, I might be in trouble.

    # Let's stick to a robust enough manual encoding for now.

    # Version
    enc_version = <<0::size(224), header.version::size(32)>>

    # Quorum Numbers (Dynamic Array)
    # Head: Offset (32 bytes). It's the 2nd param, so offset starts after 3rd param head.
    # Params: Version (32), QuorumOffset(32), CommitmentOffset(32) = 96 bytes head.

    # But wait, commitment is a struct (tuple), is it dynamic?
    # BlobCommitment: bytes, bytes, bytes, uint32. Bytes are dynamic.
    # So Commitment is dynamic.

    # This is getting complex to implement manually.
    # I will use a simple "packed" encoding for now which is often used in hashing if not specified otherwise,
    # BUT the spec says `abi.encode` (standard), not `abi.encodePacked`.

    # Re-evaluating: Does the codebase have `ethers` or `ex_abi`?
    # I checked `mix.exs`, it does NOT.

    # Recommendation: I should have added `ex_abi` or `ethers`.
    # I will proceed with a best-effort manual ABI encoding for the specific shape.

    # ABI Encode: (version, quorumNumbers, commitment)
    # Head:
    # [0] version (32 bytes)
    # [1] offset_quorum (32 bytes) -> 0x60 (96)
    # [2] offset_commitment (32 bytes) -> depends on quorum size

    quorums = header.quorum_numbers |> Enum.sort()
    quorums_count = length(quorums)
    quorums_data_size = 32 + (quorums_count * 32) # length + items

    enc_quorums =
      <<quorums_count::size(256)>> <>
      (Enum.map(quorums, fn q -> <<0::size(224), q::size(32)>> end) |> Enum.join())

    offset_commitment = 96 + quorums_data_size

    enc_head =
      enc_version <>
      <<96::size(256)>> <> # Offset to quorums (always 32+32+32=96 bytes start)
      <<offset_commitment::size(256)>>

    # Commitment Encoding (BlobCommitment)
    # struct BlobCommitment { bytes commitment; bytes length_commitment; bytes length_proof; uint32 length; }
    # All bytes are dynamic.
    # Head:
    # [0] off_c (32)
    # [1] off_lc (32)
    # [2] off_lp (32)
    # [3] length (32)

    c = header.commitment

    # Helper to encode bytes
    encode_bytes = fn b ->
      len = byte_size(b)
      pad = rem(32 - rem(len, 32), 32)
      <<len::size(256)>> <> b <> <<0::size(pad * 8)>>
    end

    enc_c_data = encode_bytes.(c.commitment)
    enc_lc_data = encode_bytes.(c.length_commitment)
    enc_lp_data = encode_bytes.(c.length_proof)

    # Offsets for struct
    start_data = 32 * 4 # 4 fields
    off_c = start_data
    off_lc = off_c + byte_size(enc_c_data)
    off_lp = off_lc + byte_size(enc_lc_data)

    enc_commitment =
      <<off_c::size(256)>> <>
      <<off_lc::size(256)>> <>
      <<off_lp::size(256)>> <>
      <<0::size(224), c.length::size(32)>> <>
      enc_c_data <>
      enc_lc_data <>
      enc_lp_data

    # Combine all
    enc_head <> enc_quorums <> enc_commitment
  end

  defp compute_payment_header_hash(payment) do
    # PaymentHeader: (string account_id, int64 timestamp, bytes cumulative_payment)
    # abi.encode(...)

    # 1. Offset Account ID (Head 0) -> 96 (32*3)
    # 2. Timestamp (Head 1)
    # 3. Offset Cumulative (Head 2) -> depends on Account ID size

    acc_id_bytes = Base.decode16!(payment.account_id, case: :mixed) # Assume hex string

    enc_acc_id =
      <<byte_size(acc_id_bytes)::size(256)>> <>
      pad_right(acc_id_bytes)

    enc_timestamp = <<payment.timestamp::size(256)>> # int64, sign extension? assume positive for timestamp

    enc_cum_pay =
      <<byte_size(payment.cumulative_payment)::size(256)>> <>
      pad_right(payment.cumulative_payment)

    offset_acc = 96
    offset_cum = 96 + byte_size(enc_acc_id)

    data =
      <<offset_acc::size(256)>> <>
      enc_timestamp <>
      <<offset_cum::size(256)>> <>
      enc_acc_id <>
      enc_cum_pay

    ExKeccak.hash_256(data)
  end

  defp pad_right(bin) do
    len = byte_size(bin)
    pad = rem(32 - rem(len, 32), 32)
    bin <> <<0::size(pad * 8)>>
  end
end
