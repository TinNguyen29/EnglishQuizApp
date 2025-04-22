const express = require('express');
const router = express.Router();
const scoreController = require('../controllers/scoreController');

router.post('/', scoreController.saveScore);
router.get('/:userId', scoreController.getUserScores);

module.exports = router;
