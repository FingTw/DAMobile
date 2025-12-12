const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const ProjectSchema = new Schema({
  name: { type: String, required: true },
  description: { type: String },
  owner: { type: String, required: true }, // Có thể thay bằng `ObjectId` tham chiếu tới User
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('Project', ProjectSchema);
