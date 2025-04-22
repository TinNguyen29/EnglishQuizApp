const mongoose = require('mongoose');

const scoreSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  difficulty: { type: String, enum: ['easy', 'normal', 'hard'] },
  score: Number,
  date: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Score', scoreSchema);
