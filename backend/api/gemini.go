package api

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/google/generative-ai-go/genai"
	"google.golang.org/api/option"
)

// GeminiClient manages communication with the Gemini API
type GeminiClient struct {
	client *genai.Client
	model  *genai.GenerativeModel
}

// MathResult represents a parsed mathematical expression result
type MathResult struct {
	Expression string      `json:"expr"`
	Result     interface{} `json:"result"`
	Assign     bool        `json:"assign,omitempty"`
}

// NewGeminiClient creates a new client for the Gemini API
func NewGeminiClient() (*GeminiClient, error) {
	// Get API key from environment variable
	apiKey := os.Getenv("GEMINI_API_KEY")
	if apiKey == "" {
		return nil, fmt.Errorf("GEMINI_API_KEY environment variable not set")
	}

	// Create a new Gemini client
	ctx := context.Background()
	client, err := genai.NewClient(ctx, option.WithAPIKey(apiKey))
	if err != nil {
		return nil, fmt.Errorf("failed to create genai client: %v", err)
	}

	// Create a generative model with configuration similar to your Flutter implementation
	model := client.GenerativeModel("gemini-1.5-flash")
	model.GenerationConfig = &genai.GenerationConfig{
		Temperature:     1.0,
		TopK:            64,
		TopP:            0.95,
		MaxOutputTokens: 8192,
	}

	return &GeminiClient{
		client: client,
		model:  model,
	}, nil
}

// ProcessDrawing sends the drawing to Gemini and returns the calculated results
func (g *GeminiClient) ProcessDrawing(imageData []byte) ([]MathResult, error) {
	// Create the prompt similar to your Flutter implementation
	promptText := `You have been given an image with some mathematical expressions, equations, or graphical problems, and you need to solve them. Note: Use the PEMDAS rule for solving mathematical expressions. PEMDAS stands for the Priority Order: Parentheses, Exponents, Multiplication and Division (from left to right), Addition and Subtraction (from left to right). Parentheses have the highest priority, followed by Exponents, then Multiplication and Division, and lastly Addition and Subtraction. For example:
		Q. 2 + 3 * 4
		(3 * 4) => 12, 2 + 12 = 14.
		Q. 2 + 3 + 5 * 4 - 8 / 2
		5 * 4 => 20, 8 / 2 => 4, 2 + 3 => 5, 5 + 20 => 25, 25 - 4 => 21.
		YOU CAN HAVE FIVE TYPES OF EQUATIONS/EXPRESSIONS IN THIS IMAGE, AND ONLY ONE CASE SHALL APPLY EVERY TIME:
		Following are the cases:
		1. Simple mathematical expressions like 2 + 2, 3 * 4, 5 / 6, 7 - 8, etc.: In this case, solve and return the answer in the format of a LIST OF ONE DICT [{"expr": given expression, "result": calculated answer}].
		2. Set of Equations like x^2 + 2x + 1 = 0, 3y + 4x = 0, 5x^2 + 6y + 7 = 12, etc.: In this case, solve for the given variable, and the format should be a COMMA SEPARATED LIST OF DICTS, with dict 1 as {"expr": "x", "result": 2, "assign": True} and dict 2 as {"expr": "y", "result": 5, "assign": True}. This example assumes x was calculated as 2, and y as 5. Include as many dicts as there are variables.
		3. Assigning values to variables like x = 4, y = 5, z = 6, etc.: In this case, assign values to variables and return another key in the dict called {"assign": True}, keeping the variable as "expr" and the value as "result" in the original dictionary. RETURN AS A LIST OF DICTS.
		4. Analyzing Graphical Math problems, which are word problems represented in drawing form, such as cars colliding, trigonometric problems, problems on the Pythagorean theorem, adding runs from a cricket wagon wheel, etc. These will have a drawing representing some scenario and accompanying information with the image. PAY CLOSE ATTENTION TO DIFFERENT COLORS FOR THESE PROBLEMS. You need to return the answer in the format of a LIST OF ONE DICT [{"expr": given expression, "result": calculated answer}].
		5. Detecting Abstract Concepts that a drawing might show, such as love, hate, jealousy, patriotism, or a historic reference to war, invention, discovery, quote, etc. USE THE SAME FORMAT AS OTHERS TO RETURN THE ANSWER, where "expr" will be the explanation of the drawing, and "result" will be the abstract concept.
		Analyze the equation or expression in this image and return the answer according to the given rules:
		Please provide the answer in a JSON format only, no additional text.`

	// Create parts for the prompt
	prompt := []genai.Part{
		genai.Text(promptText),
		genai.ImageData("image/png", imageData),
	}

	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()

	// Generate content using the Gemini model
	resp, err := g.model.GenerateContent(ctx, prompt...)
	if err != nil {
		return nil, fmt.Errorf("error generating content: %v", err)
	}

	if len(resp.Candidates) == 0 || len(resp.Candidates[0].Content.Parts) == 0 {
		return nil, fmt.Errorf("no response from model")
	}

	// Extract the text response
	responseText := resp.Candidates[0].Content.Parts[0].GetText()
	log.Printf("Gemini response: %s", responseText)

	// Parse the JSON response
	var results []MathResult
	if err := json.Unmarshal([]byte(responseText), &results); err != nil {
		// If it fails, try to find JSON in the text (in case model outputs additional text)
		jsonStart := 0
		jsonEnd := len(responseText)
		
		// Look for starting bracket
		for i, char := range responseText {
			if char == '[' {
				jsonStart = i
				break
			}
		}
		
		// Look for ending bracket (from the end)
		for i := len(responseText) - 1; i >= 0; i-- {
			if responseText[i] == ']' {
				jsonEnd = i + 1
				break
			}
		}
		
		// Try parsing the extracted JSON portion
		if jsonEnd > jsonStart {
			extractedJSON := responseText[jsonStart:jsonEnd]
			if err := json.Unmarshal([]byte(extractedJSON), &results); err != nil {
				return nil, fmt.Errorf("error parsing response as JSON: %v", err)
			}
		} else {
			return nil, fmt.Errorf("error parsing response as JSON: %v", err)
		}
	}

	return results, nil
}

// Close closes the Gemini client
func (g *GeminiClient) Close() {
	if g.client != nil {
		g.client.Close()
	}
}