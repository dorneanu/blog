package main

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	"testing"
)

func TestTasks(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "Task API Suite")
}


var _ = Describe("Task API", func() {
	var (
		store  *TaskStore
		server *Server
	)
	BeforeEach(func() {
		store = NewTaskStore()
		server = &Server{store: store}
	})

	Describe("POST /task/create", func() {
		Context("when creating a new task", func() {
			It("should create and return a task with an ID", func() {
				task := Task{
					Title:       "Test Task",
					Description: "Test Description",
					Done:        false,
				}

				payload, err := json.Marshal(task)
				Expect(err).NotTo(HaveOccurred())

				req := httptest.NewRequest(http.MethodPost, "/task/create",
					bytes.NewBuffer(payload))
				w := httptest.NewRecorder()

				server.handleCreateTask(w, req)

				Expect(w.Code).To(Equal(http.StatusOK))

				var response Task
				err = json.NewDecoder(w.Body).Decode(&response)
				Expect(err).NotTo(HaveOccurred())
				Expect(response.ID).To(Equal(1))
				Expect(response.Title).To(Equal("Test Task"))
			})

			It("should handle invalid JSON payload", func() {
				req := httptest.NewRequest(http.MethodPost, "/task/create",
					bytes.NewBufferString("invalid json"))
				w := httptest.NewRecorder()

				server.handleCreateTask(w, req)

				Expect(w.Code).To(Equal(http.StatusBadRequest))
			})
		})
	})

	Describe("GET /task/get", func() {
		Context("when fetching an existing task", func() {
			var createdTask Task

			BeforeEach(func() {
				task := Task{
					Title:       "Test Task",
					Description: "Test Description",
					Done:        false,
				}
				createdTask = store.CreateTask(task)
			})

			It("should return the correct task", func() {
				req := httptest.NewRequest(http.MethodGet, "/task/get?id=1", nil)
				w := httptest.NewRecorder()

				server.handleGetTask(w, req)

				Expect(w.Code).To(Equal(http.StatusOK))

				var response Task
				err := json.NewDecoder(w.Body).Decode(&response)
				Expect(err).NotTo(HaveOccurred())
				Expect(response).To(Equal(createdTask))
			})
		})

		Context("when fetching a non-existent task", func() {
			It("should return a 404 error", func() {
				req := httptest.NewRequest(http.MethodGet, "/task/get?id=999", nil)
				w := httptest.NewRecorder()

				server.handleGetTask(w, req)

				Expect(w.Code).To(Equal(http.StatusNotFound))
			})
		})

		Context("when using invalid task ID", func() {
			It("should handle non-numeric ID gracefully", func() {
				req := httptest.NewRequest(http.MethodGet, "/task/get?id=invalid", nil)
				w := httptest.NewRecorder()

				server.handleGetTask(w, req)

				Expect(w.Code).To(Equal(http.StatusNotFound))
			})
		})
	})
})
