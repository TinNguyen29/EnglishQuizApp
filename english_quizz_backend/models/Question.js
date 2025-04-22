const mongoose = require('mongoose');

const questionSchema = new mongoose.Schema(
  {
    content: {
      type: String,
      required: [true, 'Câu hỏi không được để trống']
    },
    image_url: {
      type: String,
      default: ''
    },
    options: {
      type: [String],
      required: [true, 'Cần phải có các đáp án'],
      validate: {
        validator: function (arr) {
          return Array.isArray(arr) && arr.length === 4;
        },
        message: 'Phải có đúng 4 đáp án'
      }
    },
    correct_answer: {
      type: Number,
      required: [true, 'Cần chỉ định đáp án đúng'],
      enum: {
        values: [0, 1, 2, 3],
        message: 'Đáp án đúng phải là một trong các giá trị 0, 1, 2, 3'
      }
    },
    level: {
      type: String,
      enum: ['easy', 'normal', 'hard'],
      required: [true, 'Cần chỉ định độ khó cho câu hỏi']
    }
  },
  {
    timestamps: true
  }
);

module.exports = mongoose.model('Question', questionSchema);
