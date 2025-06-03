const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const router = express.Router();
const scoreController = require('./controllers/scoreController');
const quizDetailsController = require('./controllers/quizDetailsController');
require('dotenv').config();

// Khởi tạo app từ express
const app = express();

// Import các routes
const uploadRoutes = require('./routes/upload');
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
app.use('/uploads', express.static('uploads'));

// Kiểm tra server
app.get('/', (req, res) => {
  res.send('Backend đang hoạt động!');
});

// Các routes chính
app.use('/api', authRoutes);               
app.use('/api/questions', questionRoutes);  
app.use('/api/score', scoreRoutes);         
app.use("/api/quiz-details", quizDetailRoutes);
app.use('/api', uploadRoutes);
// Khởi chạy server
app.listen(PORT, () => {
  console.log(`Server đang chạy tại: http://localhost:${PORT}`);
});
