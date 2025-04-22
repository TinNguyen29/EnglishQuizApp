const User = require('./models/user');
const bcrypt = require('bcrypt');

async function createDefaultAdmin() {
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
    console.log('Tạo tài khoản admin mặc định thành công!');
  }
}

module.exports = createDefaultAdmin;
