const mongoose = require('mongoose');

const quizDetailSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  quizId: { type: String },
  questionId: { type: mongoose.Schema.Types.ObjectId, ref: 'Question' },
  answer: String, // Ghi nhận đáp án người dùng chọn
  timeTaken: Number,
  highestScore: Number,
  level: { type: String, enum: ['easy', 'normal', 'hard']},
  isCorrect: { type: Boolean }  // Trường để kiểm tra đáp án đúng hay sai
});

// Middleware để ghi lại level và kiểm tra đáp án
quizDetailSchema.pre('save', async function(next) {
  const question = await mongoose.model('Question').findById(this.questionId);
  if (question) {
    this.level = question.level; // Ghi lại level từ câu hỏi
    this.isCorrect = this.answer === question[question.correct_answer]; // So sánh đáp án người dùng với đáp án đúng
  }
  next();
});

module.exports = mongoose.model('QuizDetail', quizDetailSchema);
