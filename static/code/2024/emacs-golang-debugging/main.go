package main


import (
	"log"
    "net/http"
)

func main() {
	store := NewTaskStore()
	server := &Server{store: store}
	http.HandleFunc("/task/create", server.handleCreateTask)
	http.HandleFunc("/task/get", server.handleGetTask)

	log.Printf("Starting server on :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
