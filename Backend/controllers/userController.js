const User = require('../models/User');
const bcrypt = require('bcryptjs');

// Đăng ký user mới (có mã hóa mật khẩu)
exports.registerUser = async (req, res) => {
  const { name, email, password, role } = req.body;

  try {
    let user = await User.findOne({ email });
    if (user) {
      return res.status(400).json({ message: 'User already exists' });
    }

    user = new User({
      name,
      email,
      password,
      role,
    });

    const salt = await bcrypt.genSalt(10);
    user.password = await bcrypt.hash(password, salt);

    await user.save();
    res.status(201).json({ message: 'User registered successfully' });

  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Lấy tất cả user
exports.getAllUsers = async (req, res) => {
  try {
    const users = await User.find().select('-password'); // Bỏ qua field password
    res.json(users);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
