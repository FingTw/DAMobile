const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const StorySchema = new Schema({
  title: { type: String, required: true },
  description: { type: String, required: true },
  storyPoints: { type: Number, default: 0 },
  priority: {
    type: String,
    enum: ['Lowest', 'Low', 'Medium', 'High', 'Highest'],
    default: 'Medium',
  },
  project: { type: Schema.Types.ObjectId, ref: 'Project', required: true },
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('Story', StorySchema);
