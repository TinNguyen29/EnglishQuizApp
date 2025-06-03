// controllers/quizDetailsController.js
const QuizDetail = require('../models/QuizDetail'); // Đảm bảo import đúng model
const User = require('../models/User'); // Để tìm userId từ email
const mongoose = require('mongoose'); // Import mongoose để sử dụng ObjectId nếu cần

// Hàm để lưu chi tiết quiz (đã được gọi từ ScoreService.saveQuizDetails của Flutter)
exports.saveQuizDetails = async (req, res) => {
    try {
      const { userId, quizId, level, answers, score, duration } = req.body;
  
      if (
        !userId || !quizId || !level ||
        !Array.isArray(answers) || answers.length === 0 ||
        score == null || duration == null
      ) {
        return res.status(400).json({ message: "❗ Dữ liệu đầu vào không hợp lệ." });
      }
  
      const parsedAnswers = answers.map(ans => ({
        questionId: new mongoose.Types.ObjectId(ans.questionId),
        selectedAnswer: ans.selectedAnswer,
        timeTaken: ans.timeTaken || 0,
        isCorrect: ans.isCorrect
      }));
  
      const newQuizDetail = new QuizDetail({
        userId,
        quizId,
        level,
        answers: parsedAnswers,
        score,
        duration,
        createdAt: new Date()
      });
  
      await newQuizDetail.save();
      res.status(201).json({ message: "✅ Chi tiết bài làm đã được lưu thành công!", data: newQuizDetail });
  
    } catch (error) {
      console.error("❌ Lỗi khi lưu chi tiết quiz:", error.message);
      res.status(500).json({ message: "❌ Server lỗi", error: error.message });
    }
  };   

// Hàm để lấy lịch sử quiz của một người dùng cụ thể
exports.getUserQuizHistory = async (req, res) => {
    try {
        const userEmail = req.query.email; // Lấy email từ query parameter

        if (!userEmail) {
            return res.status(400).json({ message: 'Email người dùng là bắt buộc.' });
        }

        // Tìm userId từ email
        const user = await User.findOne({ email: userEmail });
        if (!user) {
            // Nếu không tìm thấy người dùng, trả về mảng rỗng để frontend không báo lỗi 404
            return res.status(200).json([]);
        }

        // Tìm tất cả các bài quiz đã làm của người dùng đó
        // Sắp xếp theo createdAt giảm dần (bài mới nhất lên đầu)
        const history = await QuizDetail.find({ userId: user._id })
                                        .sort({ createdAt: -1 }) // Sắp xếp giảm dần theo thời gian tạo
                                        .limit(10); // Giới hạn lấy 10 bài quiz gần nhất

        res.status(200).json(history);
    } catch (error) {
        console.error('Lỗi khi lấy lịch sử quiz:', error);
        res.status(500).json({ message: 'Lỗi server khi lấy lịch sử quiz', error: error.message });
    }
};

// Hàm để lấy chi tiết một bài quiz cụ thể theo quizId (cho chức năng làm lại bài)
exports.getQuizDetailsById = async (req, res) => {
    try {
        const quizId = req.params.quizId; // Lấy quizId từ URL params

        // Tìm chi tiết quiz bằng quizId (là một String, không phải _id của MongoDB)
        const quizDetail = await QuizDetail.findOne({ quizId: quizId });

        if (!quizDetail) {
            return res.status(404).json({ message: 'Không tìm thấy chi tiết bài quiz.' });
        }

        res.status(200).json(quizDetail);
    } catch (error) {
        console.error('Lỗi khi lấy chi tiết quiz theo ID:', error);
        res.status(500).json({ message: 'Lỗi server khi lấy chi tiết quiz', error: error.message });
    }
};
