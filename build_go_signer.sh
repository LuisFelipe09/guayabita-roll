#!/bin/bash

# Script to build the Go signer binary
# This should be run from the project root

set -e

echo "Building EigenDA Go signer..."

cd apps/eigenda-signer

# Initialize go module if needed
if [ ! -f "go.sum" ]; then
    echo "Initializing Go modules..."
    go mod tidy
fi

# Build the binary
echo "Compiling Go binary..."
go build -o ../../backend/priv/eigenda-signer main.go

echo "✅ Go signer built successfully at: backend/priv/eigenda-signer"
echo ""
echo "You can now use GuayabitaRoll.EigenDA.GoSigner from Elixir!"
