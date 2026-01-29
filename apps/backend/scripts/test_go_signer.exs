#!/usr/bin/env elixir

# Script de prueba para el Go Signer
# Uso: source .env && mix run scripts/test_go_signer.exs

IO.puts("\n🧪 Test de EigenDA Go Signer\n")

alias GuayabitaRoll.EigenDA.GoSigner

# Get private key from env
private_key = System.get_env("EIGENDA_PRIVATE_KEY")

if !private_key do
  IO.puts("❌ Error: EIGENDA_PRIVATE_KEY no está configurada")
  IO.puts("   Ejecuta: source .env")
  System.halt(1)
end

# Test data
test_data = "Hello from Guayabita Roll via Go Signer! Testing EigenDA V2 integration."

IO.puts("📤 Dispersando blob a EigenDA...")
IO.puts("   Data: #{test_data}")
IO.puts("   Size: #{byte_size(test_data)} bytes")

case GoSigner.disperse_blob(test_data, private_key) do
  {:ok, blob_key} ->
    IO.puts("\n✅ Blob dispersado exitosamente!")
    IO.puts("   Blob Key: #{Base.encode16(blob_key)}")
    
    IO.puts("\n🔍 Consultando estado del blob...")
    
    case GoSigner.get_blob_status(blob_key, private_key) do
      {:ok, status} ->
        IO.puts("   ✅ Status: #{inspect(status)}")
        
      {:error, reason} ->
        IO.puts("   ⚠️  Error consultando status: #{inspect(reason)}")
    end
    
  {:error, reason} ->
    IO.puts("\n❌ Error dispersando blob: #{inspect(reason)}")
    IO.puts("\n💡 Posibles causas:")
    IO.puts("   - Go signer no está compilado (ejecuta: ./build_go_signer.sh)")
    IO.puts("   - La private key no tiene fondos en Sepolia")
    IO.puts("   - Problema de red o configuración")
    System.halt(1)
end

IO.puts("\n✅ Test completado!\n")
