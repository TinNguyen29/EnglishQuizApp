const Score = require('../models/score');
const User = require('../models/user'); // phải import User

// ✅ Ghi điểm có gắn user_id từ email
exports.saveScore = async (req, res) => {
  try {
    const { email, score, level, mode } = req.body;

    // Tìm user theo email
    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'Không tìm thấy người dùng' });

    // Tạo điểm mới với user_id
    const newScore = new Score({
      user_id: user._id,
      score,
      mode,
      date: new Date()
    });

    await newScore.save();
    res.status(201).json(newScore);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ✅ Lấy điểm của 1 user cụ thể
exports.getUserScores = async (req, res) => {
  try {
    const scores = await Score.find({ user_id: req.params.userId });
    res.json(scores);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ✅ Bảng xếp hạng (top điểm)
exports.getRankingByMode = async (req, res) => {
  const mode = req.params.mode;

  try {
    const topScores = await Score.aggregate([
      { $match: { mode } },
      {
        $lookup: {
          from: 'users',
          localField: 'user_id',
          foreignField: '_id',
          as: 'userInfo'
        }
      },
      { $unwind: '$userInfo' },
      {
        $group: {
          _id: '$user_id',
          username: { $first: '$userInfo.username' },
          email: { $first: '$userInfo.email' },
          maxScore: { $max: '$score' }
        }
      },
      { $sort: { maxScore: -1 } },
      { $limit: 10 }
    ]);

    res.json(topScores);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
};

