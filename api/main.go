package main

import (
	"encoding/json"
	"fmt"
	"net"
	"net/http"
	"strings"
	"sync/atomic"
	"time"
)

type TimeResponse struct {
	CurrentTime string `json:"current_time"`
	Message     string `json:"message"`
	ClientIP    string `json:"client_ip"`
	RequestMode string `json:"request_mode"`
}

type HealthResponse struct {
	Status         string    `json:"status"`
	Uptime         string    `json:"uptime"`
	CurrentTime    time.Time `json:"current_time"`
	RequestsServed uint64    `json:"requests_served"`
}

var (
	startTime      = time.Now()
	requestsServed atomic.Uint64
)

func getClientIP(r *http.Request) string {
	// Check for X-Forwarded-For header (common with load balancers/proxies)
	forwarded := r.Header.Get("X-Forwarded-For")
	if forwarded != "" {
		return strings.Split(forwarded, ",")[0]
	}

	// Direct IP from RemoteAddr
	ip, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		return r.RemoteAddr
	}

	return ip
}

func timeHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet || r.URL.Path != "/" {
		http.Error(w, "Not Found", http.StatusNotFound)
		return
	}

	requestsServed.Add(1)

	response := TimeResponse{
		CurrentTime: time.Now().UTC().Format(time.RFC3339),
		Message:     "Automate All The Things",
		ClientIP:    getClientIP(r),
		RequestMode: r.Proto,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

func healthCheckHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet || r.URL.Path != "/health" {
		http.Error(w, "Not Found", http.StatusNotFound)
		return
	}

	uptime := time.Since(startTime)

	response := HealthResponse{
		Status:         "healthy",
		Uptime:         uptime.Round(time.Second).String(),
		CurrentTime:    time.Now().UTC(),
		RequestsServed: requestsServed.Load(),
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

func main() {
	http.HandleFunc("/", timeHandler)
	http.HandleFunc("/health", healthCheckHandler)

	fmt.Println("Server starting on port 8080")
	err := http.ListenAndServe(":8080", nil)
	if err != nil {
		fmt.Printf("Server error: %v", err)
	}
}
