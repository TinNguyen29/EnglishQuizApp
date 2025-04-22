const express = require('express');
const router = express.Router();
const questionController = require('../controllers/questionController');
const { authenticateToken, requireAdmin } = require('../middleware/authMiddleware');

router.get('/random', questionController.getRandomQuestionsByLevel); 

// Đảm bảo các handler là các hàm hợp lệ
router.post('/', authenticateToken, requireAdmin, questionController.createQuestion);
router.put('/:id', authenticateToken, requireAdmin, questionController.updateQuestion);
router.delete('/:id', authenticateToken, requireAdmin, questionController.deleteQuestion);

// Mọi người đều có thể xem câu hỏi theo level
router.get('/', questionController.getAllQuestions); 
router.get('/:id', questionController.getQuestionById); 
module.exports = router;
