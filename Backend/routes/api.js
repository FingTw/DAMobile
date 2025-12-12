const express = require('express');
const router = express.Router();

// Import controllers
const projectController = require('../controllers/projectController');
const taskController = require('../controllers/taskController');
const userController = require('../controllers/userController');
const sprintController = require('../controllers/sprintController');
const storyController = require('../controllers/storyController');


// --- User Routes ---
router.post('/users/register', userController.registerUser);
router.get('/users', userController.getAllUsers);


// --- Project Routes ---
router.get('/projects', projectController.getAllProjects);
router.post('/projects', projectController.createProject);
// Get project-specific items
router.get('/projects/:projectId/tasks', projectController.getTasksByProject);
router.get('/projects/:projectId/sprints', sprintController.getSprintsByProject);
router.get('/projects/:projectId/stories', storyController.getStoriesByProject); // Product Backlog


// --- Sprint Routes ---
router.post('/sprints', sprintController.createSprint);
// Get tasks for a specific sprint
router.get('/sprints/:sprintId/tasks', taskController.getTasksBySprint);


// --- Story (User Story) Routes ---
router.post('/stories', storyController.createStory);


// --- Task Routes ---
router.post('/tasks', taskController.createTask);
router.patch('/tasks/:id/status', taskController.updateTaskStatus); // Dùng PATCH để cập nhật một phần
router.patch('/tasks/:id/assign-sprint', taskController.assignTaskToSprint); // Gán task vào sprint


module.exports = router;
