const Score = require('../models/score');
const User = require('../models/user'); // phải import User

// ✅ Ghi điểm có gắn user_id từ email
exports.saveScore = async (req, res) => {
  try {
    const { userId, score, mode, duration } = req.body;

    if (!userId || score == null || !mode || duration == null) {
      return res.status(400).json({ message: 'Thiếu dữ liệu bắt buộc' });
    }

    const newScore = new Score({
      user_id: userId,
      score,
      mode,
      duration,
      date: new Date()
    });

    await newScore.save();
    res.status(201).json({ message: '✅ Đã lưu điểm thành công', data: newScore });
  } catch (err) {
    res.status(500).json({ error: '❌ Lỗi khi lưu điểm: ' + err.message });
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
          maxScore: { $max: '$score' },
          bestDuration: { $min: '$duration' } // thời gian ngắn nhất trong các lần đạt điểm cao
        }
      },
      {
        $sort: {
          maxScore: -1,           // điểm cao nhất trước
          bestDuration: 1         // thời gian làm bài ngắn hơn sẽ đứng trước nếu bằng điểm
        }
      },
      { $limit: 10 }
    ]);

    console.log("🎯 TOP SCORES:", topScores);
    res.json(topScores);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
};


