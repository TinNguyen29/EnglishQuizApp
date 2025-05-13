const mongoose = require('mongoose');
const User = require('./models/user');
const bcrypt = require('bcrypt');
require('dotenv').config(); // đọc .env

async function createDefaultAdmin() {
  await mongoose.connect(process.env.MONGO_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true
  });
  console.log("✅ Đã kết nối MongoDB");

  const existingAdmin = await User.findOne({ username: 'admin' });
  if (!existingAdmin) {
    const hashedPassword = await bcrypt.hash('admin', 10);
    const admin = new User({
      username: 'admin',
      email: 'admin@example.com',
      password: hashedPassword,
      isAdmin: true,
    });
    await admin.save();
    console.log("✅ Tạo tài khoản admin mặc định thành công!");
  } else {
    console.log("⚠️ Tài khoản admin đã tồn tại.");
  }

  await mongoose.disconnect(); // đóng kết nối sau khi chạy
}

createDefaultAdmin();
