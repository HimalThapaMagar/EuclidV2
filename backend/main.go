package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"time"
)

type CalculationResponse struct {
	Expression string  `json:"expression"`
	Result     float64 `json:"result"`
}
func main() {
	// Define endpoint for calculation
	http.HandleFunc("/calculate", handleCalculation)

	// Enable CORS for development
	http.HandleFunc("/", enableCORS)

	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})

	// Get port from environment variable (required for Render)
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080" // Default for local development
	}
	
	fmt.Printf("Starting server at port %s at %s\n", port, time.Now().Format("2006-01-02 15:04:05"))
	log.Fatal(http.ListenAndServe(":"+port, nil))
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

    // Create a temporary file to store the uploaded image
    tempFile, err := os.CreateTemp("", "drawing-*.png")
    if err != nil {
        log.Printf("Error creating temporary file: %v", err)
        http.Error(w, "Error creating temporary file: "+err.Error(), http.StatusInternalServerError)
        return
    }
    defer tempFile.Close()
    defer os.Remove(tempFile.Name()) // Clean up temp file after processing

    // Copy uploaded file to the temporary file
    _, err = io.Copy(tempFile, file)
    if err != nil {
        log.Printf("Error saving file: %v", err)
        http.Error(w, "Error saving file: "+err.Error(), http.StatusInternalServerError)
        return
    }

    log.Printf("Saved file temporarily at: %s", tempFile.Name())

    // Prepare response
    response := CalculationResponse{
        Expression: "2+2",
        Result:     4,
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