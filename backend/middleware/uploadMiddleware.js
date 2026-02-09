import multer from 'multer';
import path from 'path';
import { fileURLToPath } from 'url';
import fs from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const uploadsDir = path.join(__dirname, '..', 'uploads');
console.log("Files will be saved in:", uploadsDir);

if (!fs.existsSync(uploadsDir)) {
    fs.mkdirSync(uploadsDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination(req, file, cb) {
    cb(null, uploadsDir);
  },
  filename(req, file, cb) {
    cb(null, `${Date.now()}-${file.originalname}`);
  }
});

const fileFilter = (req, file, cb) => {
  const ext = path.extname(file.originalname).toLowerCase();
  if (ext === '.pdf' || ext === '.jpg' || ext === '.jpeg' || ext === '.png') {
    cb(null, true);
  } else {
    cb(new Error('Only PDF/JPG/PNG files allowed'), false);
  }
};

const upload = multer({ storage, fileFilter });
export default upload;
