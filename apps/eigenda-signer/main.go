package main

import (
	"context"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"os"
	"time"

	"github.com/Layr-Labs/eigenda/api/clients/v2"
	authv2 "github.com/Layr-Labs/eigenda/core/auth/v2"
	corev2 "github.com/Layr-Labs/eigenda/core/v2"
	"github.com/Layr-Labs/eigenda/encoding/utils/codec"
)

// Request structure from Elixir
type SignRequest struct {
	Action string `json:"action"`
	Data   string `json:"data"` // hex encoded
}

// Response structure to Elixir
type SignResponse struct {
	Success   bool   `json:"success"`
	Signature string `json:"signature,omitempty"` // hex encoded
	BlobKey   string `json:"blob_key,omitempty"`  // hex encoded
	Error     string `json:"error,omitempty"`
}

func main() {
	// Get private key from environment
	privateKey := os.Getenv("EIGENDA_PRIVATE_KEY")
	if privateKey == "" {
		sendError("EIGENDA_PRIVATE_KEY environment variable not set")
		return
	}
	
	// Clean private key (remove 0x prefix if present)
	if len(privateKey) > 2 && privateKey[:2] == "0x" {
		privateKey = privateKey[2:]
	}

	// Read JSON from stdin
	var req SignRequest
	decoder := json.NewDecoder(os.Stdin)
	if err := decoder.Decode(&req); err != nil {
		sendError(fmt.Sprintf("Failed to decode request: %v", err))
		return
	}

	switch req.Action {
	case "disperse_blob":
		disperseBlob(req, privateKey)
	case "get_blob_status":
		getBlobStatus(req, privateKey)
	default:
		sendError(fmt.Sprintf("Unknown action: %s", req.Action))
	}
}

func disperseBlob(req SignRequest, privateKey string) {
	// Create signer
	signer, err := authv2.NewLocalBlobRequestSigner(privateKey)
	if err != nil {
		sendError(fmt.Sprintf("Failed to create signer: %v", err))
		return
	}

	// Create disperser client
	disp, err := clients.NewDisperserClient(&clients.DisperserClientConfig{
		Hostname:          "disperser-testnet-sepolia.eigenda.xyz",
		Port:              "443",
		UseSecureGrpcFlag: true,
	}, signer, nil, nil)
	if err != nil {
		sendError(fmt.Sprintf("Failed to create disperser client: %v", err))
		return
	}

	// Decode data
	data, err := hex.DecodeString(req.Data)
	if err != nil {
		sendError(fmt.Sprintf("Failed to decode data: %v", err))
		return
	}

	// Pad data for BN254
	data = codec.ConvertByPaddingEmptyByte(data)

	// Disperse blob
	ctx, cancel := context.WithTimeout(context.Background(), time.Second*30)
	defer cancel()

	quorums := []uint8{0, 1}
	status, blobKey, err := disp.DisperseBlob(ctx, data, corev2.BlobVersion(0), quorums)
	if err != nil {
		sendError(fmt.Sprintf("Failed to disperse blob: %v", err))
		return
	}

	// Send success response
	resp := SignResponse{
		Success: true,
		BlobKey: hex.EncodeToString(blobKey[:]),
	}
	
	// Add status info
	fmt.Fprintf(os.Stderr, "Blob dispersed with status: %v\n", status)
	
	sendResponse(resp)
}

func getBlobStatus(req SignRequest, privateKey string) {
	// Create signer
	signer, err := authv2.NewLocalBlobRequestSigner(privateKey)
	if err != nil {
		sendError(fmt.Sprintf("Failed to create signer: %v", err))
		return
	}

	// Create disperser client
	disp, err := clients.NewDisperserClient(&clients.DisperserClientConfig{
		Hostname:          "disperser-testnet-sepolia.eigenda.xyz",
		Port:              "443",
		UseSecureGrpcFlag: true,
	}, signer, nil, nil)
	if err != nil {
		sendError(fmt.Sprintf("Failed to create disperser client: %v", err))
		return
	}

	// Decode blob key
	blobKeyBytes, err := hex.DecodeString(req.Data)
	if err != nil {
		sendError(fmt.Sprintf("Failed to decode blob key: %v", err))
		return
	}

	// Convert to BlobKey type (32 bytes array)
	var blobKey corev2.BlobKey
	copy(blobKey[:], blobKeyBytes)

	// Get blob status
	ctx, cancel := context.WithTimeout(context.Background(), time.Second*10)
	defer cancel()

	status, err := disp.GetBlobStatus(ctx, blobKey)
	if err != nil {
		sendError(fmt.Sprintf("Failed to get blob status: %v", err))
		return
	}

	// Send success response
	resp := SignResponse{
		Success: true,
	}
	
	// Add status info to stderr for debugging
	fmt.Fprintf(os.Stderr, "Blob status: %v\n", status)
	
	sendResponse(resp)
}

func sendError(msg string) {
	resp := SignResponse{
		Success: false,
		Error:   msg,
	}
	sendResponse(resp)
}

func sendResponse(resp SignResponse) {
	encoder := json.NewEncoder(os.Stdout)
	if err := encoder.Encode(resp); err != nil {
		fmt.Fprintf(os.Stderr, "Failed to encode response: %v\n", err)
		os.Exit(1)
	}
}
