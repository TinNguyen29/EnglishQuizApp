const QuizDetails = require('../models/quizDetails'); // Đảm bảo import đúng model
const User = require('../models/User'); // Để tìm userId từ email

exports.getUserQuizHistory = async (req, res) => {
    try {
        const userEmail = req.query.email; // Lấy email từ query parameter

        if (!userEmail) {
            return res.status(400).json({ message: 'Email người dùng là bắt buộc.' });
        }

        // Tìm userId từ email
        const user = await User.findOne({ email: userEmail });
        if (!user) {
            // Nếu không tìm thấy người dùng, trả về danh sách rỗng hoặc 404 tùy logic mong muốn
            return res.status(200).json([]); // Trả về mảng rỗng nếu không có user
            // Hoặc: return res.status(404).json({ message: 'Không tìm thấy người dùng.' });
        }

        // Tìm tất cả các bài quiz đã làm của người dùng đó
        // Sắp xếp theo createdAt giảm dần (bài mới nhất lên đầu)
        const history = await QuizDetails.find({ userId: user._id })
                                        .sort({ createdAt: -1 }); // Sắp xếp giảm dần theo thời gian tạo

        res.status(200).json(history);
    } catch (error) {
        console.error('Lỗi khi lấy lịch sử quiz:', error);
        res.status(500).json({ message: 'Lỗi server khi lấy lịch sử quiz', error: error.message });
    }
};

// (Tùy chọn) Hàm để lấy chi tiết một bài quiz cụ thể theo ID
exports.getQuizDetailsById = async (req, res) => {
    try {
        const quizId = req.params.quizId; // Lấy quizId từ URL params

        const quizDetail = await QuizDetails.findById(quizId); // Tìm theo _id của QuizDetails

        if (!quizDetail) {
            return res.status(404).json({ message: 'Không tìm thấy chi tiết bài quiz.' });
        }

        res.status(200).json(quizDetail);
    } catch (error) {
        console.error('Lỗi khi lấy chi tiết quiz theo ID:', error);
        res.status(500).json({ message: 'Lỗi server khi lấy chi tiết quiz', error: error.message });
    }
};