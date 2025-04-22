const express = require('express');
const router = express.Router();
const quizDetailsController = require('../controllers/quizDetailsController');

router.post('/', quizDetailsController.saveQuizDetail);
router.get('/:userId', quizDetailsController.getUserQuizDetails);

module.exports = router;
