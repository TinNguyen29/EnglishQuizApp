const QuizDetail = require('../models/QuizDetail');

exports.saveQuizDetail = async (req, res) => {
  try {
    const detail = new QuizDetail(req.body);
    await detail.save();
    res.status(201).json(detail);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.getUserQuizDetails = async (req, res) => {
  try {
    const details = await QuizDetail.find({ userId: req.params.userId });
    res.json(details);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
