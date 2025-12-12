const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
require('dotenv').config();

const connectDB = require('./config/db');
const apiRoutes = require('./routes/api');

const app = express();

// Kết nối cơ sở dữ liệu
connectDB();

// Middlewares
app.use(cors()); // Cho phép request từ domain khác
app.use(bodyParser.json()); // Parse JSON body

// Routes
app.use('/api', apiRoutes); // Tất cả các route sẽ có tiền tố /api

app.get('/', (req, res) => {
  res.send('Welcome to Scrum Project Management API!');
});

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => console.log(`Server is running on port ${PORT}`));
