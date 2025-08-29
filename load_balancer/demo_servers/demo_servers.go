package main

import (
	"fmt"
	"log"
	"net/http"
	"io"
	"strings"
)

func startServer(port string) {
	mux := http.NewServeMux()

	mux.HandleFunc("/api/v1", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(404)
		res := fmt.Sprintf("Hello From Server: %s", port)
		io.Copy(w, strings.NewReader(res))
	})

	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(200)
	})

	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(404)
		io.Copy(w, strings.NewReader("Not Found"))
	})

	server := &http.Server{
		Addr:    fmt.Sprintf(":%s", port),
		Handler: mux,
	}

	log.Printf("Starting server on port %s\n", port)

	if err := server.ListenAndServe(); err != nil {
		log.Fatalf("Failed to start server on port %s: %v", port, err)
	}
}

func main() {
	go startServer("3001")
	go startServer("3002")
	go startServer("3003")

	select {}
}

