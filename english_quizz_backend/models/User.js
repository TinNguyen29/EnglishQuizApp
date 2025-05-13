const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  username: String,
  email: String,
  password: String,
  isAdmin: Boolean
});

module.exports = mongoose.models.User || mongoose.model('User', userSchema);
