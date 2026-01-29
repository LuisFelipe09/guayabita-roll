# EigenDA Go Signer - Setup Instructions

## Prerequisites

You need to install Go to build the signer. 

### Install Go on macOS

```bash
# Using Homebrew
brew install go

# Or download from official site
# https://go.dev/dl/
```

### Verify Installation

```bash
go version
# Should output: go version go1.21.x darwin/arm64 (or similar)
```

## Building the Signer

Once Go is installed, run:

```bash
./build_go_signer.sh
```

This will:
1. Download EigenDA Go dependencies
2. Compile the signer binary
3. Place it in `apps/backend/priv/eigenda-signer`

## Usage from Elixir

```elixir
alias GuayabitaRoll.EigenDA.GoSigner

# Disperse a blob
{:ok, blob_key} = GoSigner.disperse_blob("Hello World", private_key)

# Get blob status
{:ok, status} = GoSigner.get_blob_status(blob_key, private_key)
```

## Testing

```bash
# Test the Go signer directly
cd apps/eigenda-signer
echo '{"action":"disperse_blob","private_key":"YOUR_KEY","data":"48656c6c6f"}' | go run main.go
```

## Troubleshooting

### "go: command not found"
Install Go using the instructions above.

### "Failed to create signer"
Check that your private key is valid (64 hex characters without 0x prefix).

### "Failed to disperse blob"
- Ensure you have funds deposited in the EigenDA payment vault
- Check that you're using the correct private key
- Verify network connectivity to disperser-testnet-sepolia.eigenda.xyz:443
