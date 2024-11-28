package main

import (
    "fmt"
)

type Task struct {
    ID          int    `json:"id"`
    Title       string `json:"title"`
    Description string `json:"description"`
    Done        bool   `json:"done"`
}
type TaskStore struct {
    tasks  map[int]Task
    nextID int
}

func NewTaskStore() *TaskStore {
	return &TaskStore{
		tasks:  make(map[int]Task),
		nextID: 1,
	}
}

// CreateTask stores a given Task internally
func (ts *TaskStore) CreateTask(task Task) Task {
	task.ID = ts.nextID
	ts.tasks[task.ID] = task
	ts.nextID++
	return task
}

// GetTask retrieves a Task by ID
func (ts *TaskStore) GetTask(id int) (Task, error) {
	task, exists := ts.tasks[id]
	if !exists {
		return Task{}, fmt.Errorf("task with id %d not found", id)
	}
	return task, nil
}

// UpdateTask updates task ID with a new Task object
func (ts *TaskStore) UpdateTask(id int, task Task) error {
	if _, exists := ts.tasks[id]; !exists {
		return fmt.Errorf("task with id %d not found", id)
	}
	task.ID = id
	ts.tasks[id] = task
	return nil
}
