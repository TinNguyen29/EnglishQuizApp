const Score = require('../models/Score');

exports.saveScore = async (req, res) => {
  try {
    const score = new Score(req.body);
    await score.save();
    res.status(201).json(score);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.getUserScores = async (req, res) => {
  try {
    const scores = await Score.find({ userId: req.params.userId });
    res.json(scores);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
