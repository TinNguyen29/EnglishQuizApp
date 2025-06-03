const User = require('../models/User');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET;


exports.register = async (req, res) => {
  const { email, password, username, role } = req.body;

  const existing = await User.findOne({ email });
  if (existing) return res.status(400).json({ message: 'Email đã tồn tại' });

  const hashedPassword = await bcrypt.hash(password, 10);
  const newUser = new User({ email, password: hashedPassword, username, role });

  await newUser.save();
  res.status(201).json({ message: 'Đăng ký thành công' });
};


exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'Không tìm thấy người dùng' });

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return res.status(401).json({ message: 'Mật khẩu không đúng' });

    if (!JWT_SECRET) {
      console.error("JWT_SECRET chưa được thiết lập");
      return res.status(500).json({ message: "JWT_SECRET bị thiếu trên server" });
    }

    const token = jwt.sign({ userId: user._id, role: user.role }, JWT_SECRET, { expiresIn: '1d' });
    res.json({
      token,
      user: {
        id: user._id,
        username: user.username,
        email: user.email,
        role: (user.role || 'user').toString().trim().toLowerCase(),
      }
    });
  } catch (err) {
    console.error("Lỗi đăng nhập:", err);
    res.status(500).json({ message: 'Lỗi server: ' + err.message });
  }
};


exports.resetPassword = async (req, res) => {
  const { email, newPassword } = req.body;
  try {
    if (!email || !newPassword || newPassword.length < 8) {
      return res.status(400).json({ message: 'Dữ liệu không hợp lệ: Email hoặc mật khẩu không đủ dài' });
    }
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ message: 'Không tìm thấy người dùng' });
    }
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    user.password = hashedPassword;
    await user.save();
    res.status(200).json({ success: true, message: 'Đặt lại mật khẩu thành công' });
  } catch (err) {
    console.error('Lỗi reset password:', err);
    res.status(500).json({ message: 'Lỗi server: ' + err.message });
  }
};

