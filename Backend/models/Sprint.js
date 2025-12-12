const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const SprintSchema = new Schema({
  name: { type: String, required: true },
  goal: { type: String },
  startDate: { type: Date, required: true },
  endDate: { type: Date, required: true },
  project: { type: Schema.Types.ObjectId, ref: 'Project', required: true },
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('Sprint', SprintSchema);
