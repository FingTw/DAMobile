const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const TaskSchema = new Schema({
  title: { type: String, required: true },
  description: { type: String },
  status: {
    type: String,
    enum: ['Todo', 'In Progress', 'Done'],
    default: 'Todo',
  },
  priority: {
    type: String,
    enum: ['Low', 'Medium', 'High'],
    default: 'Medium',
  },
  project: { type: Schema.Types.ObjectId, ref: 'Project', required: true },
  sprint: { type: Schema.Types.ObjectId, ref: 'Sprint' }, // Liên kết tới Sprint
  story: { type: Schema.Types.ObjectId, ref: 'Story' }, // Liên kết tới User Story
  assignee: { type: Schema.Types.ObjectId, ref: 'User' }, // Tham chiếu tới User
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('Task', TaskSchema);
