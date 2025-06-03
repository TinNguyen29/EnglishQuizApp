const Score = require("../models/score");
const User = require("../models/User"); // phải import User

// ✅ Ghi điểm có gắn user_id từ email
exports.saveScore = async (req, res) => {
  try {
    const { userId, score, mode, duration } = req.body;

    if (!userId || score == null || !mode || duration == null) {
      return res.status(400).json({ message: "Thiếu dữ liệu bắt buộc" });
    }

    // Cập nhật hoặc tạo mới bản ghi Score
    const updatedScore = await Score.findOneAndUpdate(
      { user_id: userId, mode },
      { score, duration, date: new Date() },
      { upsert: true, new: true }
    );

    // Cập nhật maxScore và bestDuration trong User model
    // Đây là phần quan trọng để đảm bảo dữ liệu hiển thị trên bảng xếp hạng được cập nhật
    const user = await User.findById(userId);
    if (user) {
      // Cập nhật maxScore
      if (user.maxScore === undefined || user.maxScore === null || score > user.maxScore) {
        user.maxScore = score;
      }
      // Cập nhật bestDuration (thời gian thấp nhất là tốt nhất)
      // Đảm bảo duration không phải là null trước khi so sánh
      if (duration != null && (user.bestDuration === undefined || user.bestDuration === null || duration < user.bestDuration)) {
        user.bestDuration = duration;
      }
      await user.save();
    }


    res
      .status(201)
      .json({
        message: "✅ Đã lưu/cập nhật điểm thành công",
        data: updatedScore,
      });
  } catch (err) {
    res.status(500).json({ error: "❌ Lỗi khi lưu điểm: " + err.message });
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
          from: "users",
          localField: "user_id",
          foreignField: "_id",
          as: "userInfo",
        },
      },
      { $unwind: "$userInfo" },
      {
        $group: {
          _id: "$user_id",
          username: { $first: "$userInfo.username" },
          email: { $first: "$userInfo.email" },
          maxScore: { $max: "$score" },
          bestDuration: { $min: "$duration" }, // Đảm bảo tên trường là "bestDuration"
        },
      },
      {
        // Thêm $project stage để đảm bảo các trường là số và xử lý null
        $project: {
          _id: 1,
          username: 1,
          email: 1,
          maxScore: { $ifNull: ["$maxScore", 0] },
          bestDuration: { $ifNull: ["$bestDuration", 0] }, // Đảm bảo tên trường là "bestDuration"
        },
      },
      {
        $sort: {
          maxScore: -1, // điểm cao nhất trước
          bestDuration: 1, // thời gian làm bài ngắn hơn sẽ đứng trước nếu bằng điểm
        },
      },
      { $limit: 10 },
    ]);

    console.log("🎯 TOP SCORES:", topScores);
    res.json(topScores);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
};
