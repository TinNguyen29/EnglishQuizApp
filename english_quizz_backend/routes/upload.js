const express = require('express');
const multer = require('multer');
const path = require('path');
const router = express.Router();

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, 'uploads/'),
  filename: (req, file, cb) => cb(null, Date.now() + path.extname(file.originalname)),
});

const upload = multer({ storage });

router.post('/upload', upload.single('image'), (req, res) => {
    const imageUrl = `${req.protocol}://${req.headers.host}/uploads/${req.file.filename}`;
    res.json({ imageUrl });
  });  

module.exports = router;
