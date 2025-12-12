const Project = require('../models/Project');
const Task = require('../models/Task');

// Lấy tất cả dự án
exports.getAllProjects = async (req, res) => {
  try {
    const projects = await Project.find();
    res.json(projects);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Tạo dự án mới
exports.createProject = async (req, res) => {
  const project = new Project({
    name: req.body.name,
    description: req.body.description,
    owner: req.body.owner,
  });
  try {
    const newProject = await project.save();
    res.status(201).json(newProject);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
};

// Lấy tất cả task của một dự án
exports.getTasksByProject = async (req, res) => {
    try {
        const tasks = await Task.find({ project: req.params.projectId });
        if(tasks.length === 0) {
            return res.status(404).json({ message: 'No tasks found for this project' });
        }
        res.json(tasks);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};
