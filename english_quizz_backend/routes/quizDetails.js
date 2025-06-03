// routes/quizDetails.js
const express = require('express');
const router = express.Router();
const { authenticateToken, requireAdmin } = require('../middleware/authMiddleware');
const quizDetailsController = require('../controllers/quizDetailsController'); // Import controller

// Route để lưu chi tiết quiz (được gọi từ Flutter khi nộp bài)
router.post('/', authenticateToken, quizDetailsController.saveQuizDetails);

// Route để lấy lịch sử quiz của người dùng theo email (frontend gọi)
router.get('/', authenticateToken, quizDetailsController.getUserQuizHistory);

// Route để lấy chi tiết một bài quiz cụ thể theo quizId (chức năng làm lại bài)
router.get('/:quizId', authenticateToken, quizDetailsController.getQuizDetailsById);

module.exports = router;
