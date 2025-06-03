const mongoose = require('mongoose');

const quizDetailSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    quizId: { 
        type: String,
        required: true
    },
    level: {
        type: String,
        enum: ['easy', 'normal', 'hard'],
        required: true
    },
    answers: [{ // Mảng các câu trả lời
        questionId: { type: mongoose.Schema.Types.ObjectId, ref: 'Question', required: true },
        selectedAnswer: { type: Number },
        timeTaken: { type: Number, default: 0 },
        isCorrect: { type: Boolean, required: true }
    }],
    score: { // <-- Đổi tên từ highestScore thành score để khớp với Flutter
        type: Number,
        required: true
    },
    duration: { // <-- Thêm trường duration nếu bạn muốn lưu tổng thời gian làm bài
        type: Number,
        required: true
    },
    createdAt: { // <-- Thêm trường createdAt để sắp xếp theo thời gian
        type: Date,
        default: Date.now
    }
});

quizDetailSchema.pre('save', async function(next) {
    next();
});

module.exports = mongoose.model('QuizDetail', quizDetailSchema);
