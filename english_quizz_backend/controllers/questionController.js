const Question = require('../models/Question');

// Tạo câu hỏi mới
exports.createQuestion = async (req, res) => {
  const { content, options, correct_answer, level, image_url } = req.body;

  if (
    !content || typeof content !== 'string' ||
    !Array.isArray(options) || options.length !== 4 || options.some(opt => typeof opt !== 'string') ||
    typeof correct_answer !== 'number' || correct_answer < 0 || correct_answer > 3 ||
    !['easy', 'normal', 'hard'].includes(level)
  ) {
    return res.status(400).json({ message: '❗ Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.' });
  }

  try {
    const newQuestion = new Question({
      content,
      options,
      correct_answer,
      level,
      image_url: image_url || ''
    });

    await newQuestion.save();
    res.status(201).json(newQuestion);
  } catch (error) {
    res.status(500).json({ message: '❌ Lỗi khi lưu câu hỏi: ' + error.message });
  }
};


// Lấy tất cả câu hỏi (có thể lọc theo level)
exports.getAllQuestions = async (req, res) => {
  try {
    const filter = req.query.level ? { level: req.query.level } : {};
    const questions = await Question.find(filter);
    res.json(questions);
  } catch (error) {
    res.status(500).json({ message: '❌ Lỗi khi lấy danh sách câu hỏi: ' + error.message });
  }
};

// Lấy một câu hỏi theo ID
exports.getQuestionById = async (req, res) => {
  try {
    const question = await Question.findById(req.params.id);
    if (!question) {
      return res.status(404).json({ message: `❌ Không tìm thấy câu hỏi với ID: ${req.params.id}` });
    }
    res.json(question);
  } catch (error) {
    res.status(500).json({ message: '❌ Lỗi khi lấy câu hỏi: ' + error.message });
  }
};

// Cập nhật câu hỏi
exports.updateQuestion = async (req, res) => {
  exports.updateQuestion = async (req, res) => {
    const { content, options, correct_answer, level, image_url } = req.body;
  
    if (
      !content || typeof content !== 'string' ||
      !Array.isArray(options) || options.length !== 4 || options.some(opt => typeof opt !== 'string') ||
      typeof correct_answer !== 'number' || correct_answer < 0 || correct_answer > 3 ||
      !['easy', 'normal', 'hard'].includes(level)
    ) {
      return res.status(400).json({ message: '❗ Dữ liệu cập nhật không hợp lệ.' });
    }
  
    try {
      const updated = await Question.findByIdAndUpdate(
        req.params.id,
        {
          content,
          options,
          correct_answer,
          level,
          image_url
        },
        { new: true }
      );
  
      if (!updated) {
        return res.status(404).json({ message: `❌ Không tìm thấy câu hỏi với ID: ${req.params.id}` });
      }
  
      res.json(updated);
    } catch (error) {
      res.status(500).json({ message: '❌ Lỗi khi cập nhật câu hỏi: ' + error.message });
    }
  };  
};

// Xóa câu hỏi
exports.deleteQuestion = async (req, res) => {
  try {
    const deleted = await Question.findByIdAndDelete(req.params.id);
    if (!deleted) {
      return res.status(404).json({ message: `❌ Không tìm thấy câu hỏi với ID: ${req.params.id}` });
    }
    res.json({ message: '✅ Xóa câu hỏi thành công.' });
  } catch (error) {
    res.status(500).json({ message: '❌ Lỗi khi xóa câu hỏi: ' + error.message });
  }
};

// Lấy 10 câu hỏi ngẫu nhiên theo level
exports.getRandomQuestionsByLevel = async (req, res) => {
  try {
    const { level } = req.query;

    if (!['easy', 'normal', 'hard'].includes(level)) {
      return res.status(400).json({ message: '❗ Mức độ không hợp lệ. Vui lòng chọn: easy, normal hoặc hard.' });
    }

    const questions = await Question.aggregate([
      { $match: { level: level } },
      { $sample: { size: 10 } }
    ]);

    if (!questions || questions.length === 0) {
      return res.status(404).json({ message: `❌ Không tìm thấy câu hỏi nào cho mức độ ${level}` });
    }

    res.json(questions);
  } catch (error) {
    res.status(500).json({ message: '❌ Lỗi khi lấy câu hỏi ngẫu nhiên: ' + error.message });
  }
};
