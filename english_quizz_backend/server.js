const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const router = express.Router();
const scoreController = require('./controllers/scoreController');
require('dotenv').config();

// Khởi tạo app từ express
const app = express();

// Import các routes
const authRoutes = require('./routes/auth');
const questionRoutes = require('./routes/question');
const scoreRoutes = require('./routes/score');
const quizDetailRoutes = require('./routes/quizDetails'); 

const PORT = process.env.PORT || 3000;
const MONGO_URI = process.env.MONGO_URI;

// Kết nối MongoDB
mongoose.connect(MONGO_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true
})
.then(() => console.log('Kết nối MongoDB thành công'))
.catch(err => console.error('Lỗi kết nối MongoDB:', err));

// Middleware
app.use(cors());
app.use(express.json()); // Cho phép đọc dữ liệu JSON từ client

// Kiểm tra server
app.get('/', (req, res) => {
  res.send('Backend đang hoạt động!');
});

router.post('/', scoreController.saveScore);

// Các routes chính
app.use('/api', authRoutes);               
app.use('/api/questions', questionRoutes);  
app.use('/api/score', scoreRoutes);         
app.use("/api/quiz-details", quizDetailRoutes); 
// Khởi chạy server
app.listen(PORT, () => {
  console.log(`Server đang chạy tại: http://localhost:${PORT}`);
});
