const Story = require('../models/Story');

// Tạo user story mới
exports.createStory = async (req, res) => {
  const { title, description, storyPoints, priority, project } = req.body;
  try {
    const newStory = new Story({ title, description, storyPoints, priority, project });
    const story = await newStory.save();
    res.status(201).json(story);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Lấy tất cả user story của một dự án (Product Backlog)
exports.getStoriesByProject = async (req, res) => {
  try {
    const stories = await Story.find({ project: req.params.projectId }).sort({ priority: -1 });
    res.json(stories);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
