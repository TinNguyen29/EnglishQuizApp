const express = require('express');
const router = express.Router();
const Score = require('../models/score');
const User = require('../models/user');
const scoreController = require('../controllers/scoreController');

router.post('/', scoreController.saveScore);

router.get('/ranking/:mode', scoreController.getRankingByMode);

module.exports = router;
