const Sprint = require('../models/Sprint');

// Tạo sprint mới
exports.createSprint = async (req, res) => {
  const { name, goal, startDate, endDate, project } = req.body;
  try {
    const newSprint = new Sprint({ name, goal, startDate, endDate, project });
    const sprint = await newSprint.save();
    res.status(201).json(sprint);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Lấy tất cả sprint của một dự án
exports.getSprintsByProject = async (req, res) => {
  try {
    const sprints = await Sprint.find({ project: req.params.projectId });
    res.json(sprints);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
