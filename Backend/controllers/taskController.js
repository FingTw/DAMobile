const Task = require('../models/Task');

// Tạo task mới
exports.createTask = async (req, res) => {
  const { title, project, description, assignee, sprint, story } = req.body;

  const task = new Task({
    title,
    project, // Cần có project ID
    description,
    assignee,
    sprint, // ID của Sprint (tùy chọn)
    story, // ID của Story (tùy chọn)
  });

  try {
    const newTask = await task.save();
    res.status(201).json(newTask);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
};

// Cập nhật trạng thái task
exports.updateTaskStatus = async (req, res) => {
  try {
    const task = await Task.findById(req.params.id);
    if (!task) {
      return res.status(404).json({ message: 'Task not found' });
    }
    task.status = req.body.status; // ví dụ: "In Progress", "Done"
    const updatedTask = await task.save();
    res.json(updatedTask);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
};

// Gán task cho một sprint
exports.assignTaskToSprint = async (req, res) => {
    const { sprintId } = req.body;
    try {
        const task = await Task.findById(req.params.id);
        if (!task) {
            return res.status(404).json({ message: 'Task not found' });
        }
        task.sprint = sprintId;
        const updatedTask = await task.save();
        res.json(updatedTask);
    } catch (err) {
        res.status(400).json({ message: err.message });
    }
};


// Lấy tất cả task của một sprint
exports.getTasksBySprint = async (req, res) => {
    try {
        const tasks = await Task.find({ sprint: req.params.sprintId });
        res.json(tasks);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};
