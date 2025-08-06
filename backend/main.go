package main

import (
	"encoding/json"
	"io"
	"log"
	"net/http"
	"os"
	"sync"
	"time"
)

// Global Gemini client
var (
	geminiClient     *api.GeminiClient
	geminiClientOnce sync.Once
	geminiClientErr  error
)

// CalculationResponse represents the response sent back to the client
type CalculationResponse struct {
	Expression string      `json:"expression"`
	Result     interface{} `json:"result"`
}

func main() {
	// Initialize Gemini client
	getGeminiClient()
	if geminiClientErr != nil {
		log.Fatalf("Failed to initialize Gemini client: %v", geminiClientErr)
	}

	// Define endpoint for calculation
	http.HandleFunc("/calculate", handleCalculation)

	// Enable CORS for development
	http.HandleFunc("/", enableCORS)

	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		log.Printf("Health check received at %s", time.Now().Format("2006-01-02 15:04:05"))
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})

	// Simple test endpoint for JSON
	http.HandleFunc("/test-json", func(w http.ResponseWriter, r *http.Request) {
		enableCORS(w, r)
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(CalculationResponse{
			Expression: "test",
			Result:     123,
		})
	})

	// Get port from environment variable (required for Render)
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080" // Default for local development
	}
	
	log.Printf("Starting server at port %s at %s", port, time.Now().Format("2006-01-02 15:04:05"))
	log.Fatal(http.ListenAndServe("0.0.0.0:"+port, nil))
}

// Lazy initialization of Gemini client
func getGeminiClient() (*api.GeminiClient, error) {
	geminiClientOnce.Do(func() {
		client, err := api.NewGeminiClient()
		geminiClient = client
		geminiClientErr = err
	})
	return geminiClient, geminiClientErr
}

func enableCORS(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "POST, GET, OPTIONS, PUT, DELETE")
	w.Header().Set("Access-Control-Allow-Headers", "Accept, Content-Type, Content-Length, Authorization")

	if r.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}
}

func handleCalculation(w http.ResponseWriter, r *http.Request) {
	// Enable CORS
	enableCORS(w, r)

	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Parse multipart form with 10MB max memory
	err := r.ParseMultipartForm(10 << 20)
	if err != nil {
		log.Printf("Error parsing form: %v", err)
		http.Error(w, "Error parsing form: "+err.Error(), http.StatusBadRequest)
		return
	}

	// Get the file from the request
	file, handler, err := r.FormFile("drawing")
	if err != nil {
		log.Printf("Error retrieving file: %v", err)
		http.Error(w, "Error retrieving file: "+err.Error(), http.StatusBadRequest)
		return
	}
	defer file.Close()

	log.Printf("Received file: %s, size: %d bytes, type: %s",
		handler.Filename,
		handler.Size,
		handler.Header.Get("Content-Type"))

	// Read the file into memory
	imageData, err := io.ReadAll(file)
	if err != nil {
		log.Printf("Error reading file: %v", err)
		http.Error(w, "Error reading file: "+err.Error(), http.StatusInternalServerError)
		return
	}

	// Get Gemini client
	client, err := getGeminiClient()
	if err != nil {
		log.Printf("Error getting Gemini client: %v", err)
		http.Error(w, "Server error: "+err.Error(), http.StatusInternalServerError)
		return
	}

	// Process the image using Gemini
	results, err := client.ProcessDrawing(imageData)
	if err != nil {
		log.Printf("Error processing drawing: %v", err)
		http.Error(w, "Error processing drawing: "+err.Error(), http.StatusInternalServerError)
		return
	}

	// Create response based on the results
	var response interface{}
	if len(results) == 1 {
		// Single result
		response = CalculationResponse{
			Expression: results[0].Expression,
			Result:     results[0].Result,
		}
	} else {
		// Multiple results
		response = results
	}

	// Set content type before writing response
	w.Header().Set("Content-Type", "application/json")
	
	// Log that we're about to send the response
	log.Printf("Sending response: %+v", response)
	
	// Encode and send JSON response
	err = json.NewEncoder(w).Encode(response)
	if err != nil {
		log.Printf("Error encoding JSON response: %v", err)
		http.Error(w, "Error encoding response", http.StatusInternalServerError)
		return
	}
	
	log.Printf("Response sent successfully")
}