const express = require('express');
const cors = require('cors');
const path = require('path');
const mysql = require('mysql2/promise');
const multer = require('multer');
const axios = require('axios');
const fs = require('fs');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// VULNERABILITY: A05 - Security Misconfiguration
// Expose sensitive environment variables and configuration
app.get('/.env', (req, res) => {
  res.json({
    message: 'VULNERABILITY: A05 - Security Misconfiguration',
    description: 'Environment file exposed',
    data: {
      NODE_ENV: process.env.NODE_ENV,
      DB_HOST: process.env.DB_HOST,
      DB_USER: process.env.DB_USER,
      DB_PASSWORD: process.env.DB_PASSWORD,
      DB_NAME: process.env.DB_NAME,
      JWT_SECRET: process.env.JWT_SECRET
    }
  });
});

// VULNERABILITY: A05 - Security Misconfiguration
// Expose package.json and other sensitive files
app.get('/package.json', (req, res) => {
  try {
    const packageJson = JSON.parse(fs.readFileSync(path.join(__dirname, 'package.json'), 'utf8'));
    res.json({
      message: 'VULNERABILITY: A05 - Security Misconfiguration',
      description: 'Package.json exposed',
      data: packageJson
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to read package.json' });
  }
});

// Database connection
const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'wcorp_user',
  password: process.env.DB_PASSWORD || 'wcorp_pass',
  database: process.env.DB_NAME || 'wcorp_db',
  port: 3306
};

let db;

// Initialize database connection with retry logic
async function initDB() {
  const maxRetries = 10;
  const retryDelay = 2000;
  
  for (let i = 0; i < maxRetries; i++) {
    try {
      db = await mysql.createConnection(dbConfig);
      console.log('Connected to MySQL database');
      return;
    } catch (error) {
      console.log(`Database connection attempt ${i + 1}/${maxRetries} failed:`, error.message);
      if (i === maxRetries - 1) {
        console.error('Database connection failed after all retries:', error);
        process.exit(1);
      }
      console.log(`Retrying in ${retryDelay}ms...`);
      await new Promise(resolve => setTimeout(resolve, retryDelay));
    }
  }
}

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve the React app at /wcorp
app.use('/wcorp', express.static(path.join(__dirname, '../frontend/build')));

// VULNERABILITY: A05 - Security Misconfiguration
// Expose uploads directory without proper access controls
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = path.join(__dirname, 'uploads');
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    // VULNERABILITY: A08 - Software and Data Integrity Failures
    // No file type validation or sanitization
    cb(null, Date.now() + '-' + file.originalname);
  }
});

const upload = multer({ 
  storage: storage,
  limits: { fileSize: 10 * 1024 * 1024 } // 10MB limit
});

// VULNERABILITY: A07 - Identification and Authentication Failures
// Predictable session token generation
function generatePredictableToken(userId) {
  const secret = process.env.JWT_SECRET || 'predictable_secret_key_123';
  return Buffer.from(`${userId}-${secret}-${Date.now()}`).toString('base64');
}

// VULNERABILITY: A02 - Cryptographic Failures
// Store passwords in plain text
async function registerUser(userData) {
  try {
    const { username, email, password } = userData;
    
    // Check if user already exists
    const [existingUsers] = await db.execute(
      'SELECT id FROM users WHERE username = ? OR email = ?',
      [username, email]
    );
    
    if (existingUsers.length > 0) {
      return { success: false, message: 'Username or email already exists' };
    }
    
    // VULNERABILITY: Store password in plain text
    const [result] = await db.execute(
      'INSERT INTO users (username, email, password, role) VALUES (?, ?, ?, ?)',
      [username, email, password, 'user']
    );
    
    return { success: true, userId: result.insertId };
  } catch (error) {
    console.error('Registration error:', error);
    return { success: false, message: 'Registration failed' };
  }
}

// VULNERABILITY: A07 - Identification and Authentication Failures
// No rate limiting and predictable session tokens
async function loginUser(username, password) {
  try {
    // VULNERABILITY: No rate limiting on login attempts
    const [users] = await db.execute(
      'SELECT * FROM users WHERE username = ? AND password = ?',
      [username, password]
    );
    
    if (users.length === 0) {
      return { success: false, message: 'Invalid credentials' };
    }
    
    const user = users[0];
    
    // VULNERABILITY: Predictable session token
    const token = generatePredictableToken(user.id);
    
    // Store session in database
    await db.execute(
      'INSERT INTO sessions (user_id, token) VALUES (?, ?)',
      [user.id, token]
    );
    
    return { 
      success: true, 
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        role: user.role
      },
      token: token
    };
  } catch (error) {
    console.error('Login error:', error);
    return { success: false, message: 'Login failed' };
  }
}

// VULNERABILITY: A01 - Broken Access Control (IDOR)
// No authorization checks for user profile access
async function getUserProfile(userId) {
  try {
    const [users] = await db.execute(
      'SELECT id, username, email, role, created_at, updated_at FROM users WHERE id = ?',
      [userId]
    );
    
    if (users.length === 0) {
      return { success: false, message: 'User not found' };
    }
    
    return { success: true, user: users[0] };
  } catch (error) {
    console.error('Get user profile error:', error);
    return { success: false, message: 'Failed to get user profile' };
  }
}

// VULNERABILITY: A01 - Broken Access Control (IDOR)
// Expose sensitive data without authorization
async function getSensitiveData(userId) {
  try {
    const [data] = await db.execute(
      'SELECT * FROM sensitive_data WHERE user_id = ?',
      [userId]
    );
    
    return { success: true, data: data };
  } catch (error) {
    console.error('Get sensitive data error:', error);
    return { success: false, message: 'Failed to get sensitive data' };
  }
}

// VULNERABILITY: A01 - Broken Access Control (IDOR)
// Expose internal notes without authorization
async function getInternalNotes(userId) {
  try {
    const [notes] = await db.execute(
      'SELECT * FROM internal_notes WHERE user_id = ?',
      [userId]
    );
    
    return { success: true, notes: notes };
  } catch (error) {
    console.error('Get internal notes error:', error);
    return { success: false, message: 'Failed to get internal notes' };
  }
}

// VULNERABILITY: A10 - Server-Side Request Forgery (SSRF)
// Fetch data from user-provided URL without validation
async function fetchUrl(url) {
  try {
    // VULNERABILITY: No URL validation or filtering
    const response = await axios.get(url, {
      timeout: 5000,
      maxRedirects: 5
    });
    
    return {
      success: true,
      data: response.data,
      status: response.status,
      headers: response.headers
    };
  } catch (error) {
    return {
      success: false,
      error: error.message,
      code: error.code
    };
  }
}

// API Routes

// Registration endpoint
app.post('/api/register', async (req, res) => {
  const result = await registerUser(req.body);
  res.json(result);
});

// Login endpoint
app.post('/api/login', async (req, res) => {
  const { username, password } = req.body;
  const result = await loginUser(username, password);
  res.json(result);
});

// VULNERABILITY: A01 - Broken Access Control (IDOR)
// User profile endpoint - no authorization checks
app.get('/api/user/profile/:id', async (req, res) => {
  const userId = req.params.id;
  const result = await getUserProfile(userId);
  res.json(result);
});

// VULNERABILITY: A01 - Broken Access Control (IDOR)
// Sensitive data endpoint - no authorization checks
app.get('/api/user/sensitive/:id', async (req, res) => {
  const userId = req.params.id;
  const result = await getSensitiveData(userId);
  res.json(result);
});

// VULNERABILITY: A01 - Broken Access Control (IDOR)
// Internal notes endpoint - no authorization checks
app.get('/api/user/notes/:id', async (req, res) => {
  const userId = req.params.id;
  const result = await getInternalNotes(userId);
  res.json(result);
});

// VULNERABILITY: A10 - Server-Side Request Forgery (SSRF)
// SSRF endpoint - no URL validation
app.get('/api/fetch-url', async (req, res) => {
  const { url } = req.query;
  
  if (!url) {
    return res.json({ success: false, message: 'URL parameter required' });
  }
  
  const result = await fetchUrl(url);
  res.json(result);
});

// File upload endpoint
app.post('/api/upload', upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return res.json({ success: false, message: 'No file uploaded' });
    }
    
    // VULNERABILITY: A08 - Software and Data Integrity Failures
    // No file type validation or virus scanning
    const fileInfo = {
      filename: req.file.filename,
      originalName: req.file.originalname,
      size: req.file.size,
      path: req.file.path
    };
    
    res.json({ 
      success: true, 
      message: 'File uploaded successfully',
      file: fileInfo
    });
  } catch (error) {
    console.error('Upload error:', error);
    res.json({ success: false, message: 'Upload failed' });
  }
});

// VULNERABILITY: A03 - Injection (SQL Injection) - Legacy login endpoint
app.post('/api/legacy-login', async (req, res) => {
  try {
    const { username, password } = req.body;
    
    // VULNERABILITY: Raw SQL query without prepared statements
    const sql = `SELECT * FROM users WHERE username = '${username}' AND password = '${password}'`;
    const [results] = await db.execute(sql);
    
    if (results.length > 0) {
      const user = results[0];
      const token = generatePredictableToken(user.id);
      
      res.json({ 
        success: true, 
        user: {
          id: user.id,
          username: user.username,
          email: user.email,
          role: user.role
        },
        token: token
      });
    } else {
      res.json({ success: false, message: 'Invalid credentials' });
    }
  } catch (error) {
    res.json({ success: false, error: error.message });
  }
});

// VULNERABILITY: A03 - Injection (SQL Injection) - Search endpoint
app.post('/api/search', async (req, res) => {
  try {
    const { query } = req.body;
    
    // VULNERABILITY: Raw SQL query without prepared statements
    const sql = `SELECT * FROM users WHERE username LIKE '%${query}%' OR email LIKE '%${query}%'`;
    const [results] = await db.execute(sql);
    
    res.json({ success: true, results: results });
  } catch (error) {
    res.json({ success: false, error: error.message });
  }
});

// Admin endpoints (no proper authorization)
app.get('/api/admin/users', async (req, res) => {
  try {
    const [users] = await db.execute(
      'SELECT id, username, email, role, created_at FROM users ORDER BY id'
    );
    res.json({ success: true, users: users });
  } catch (error) {
    console.error('Get users error:', error);
    res.json({ success: false, message: 'Failed to get users' });
  }
});

app.get('/api/admin/stats', async (req, res) => {
  try {
    const [userCount] = await db.execute('SELECT COUNT(*) as count FROM users');
    const [fileCount] = await db.execute('SELECT COUNT(*) as count FROM files');
    const [sessionCount] = await db.execute('SELECT COUNT(*) as count FROM sessions');
    
    res.json({
      success: true,
      stats: {
        totalUsers: userCount[0].count,
        totalFiles: fileCount[0].count,
        totalSessions: sessionCount[0].count
      }
    });
  } catch (error) {
    console.error('Get stats error:', error);
    res.json({ success: false, message: 'Failed to get stats' });
  }
});

// Serve landing page at root
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, '../frontend/public', 'index-landing.html'));
});

// Serve React app for /wcorp routes
app.get('/wcorp/*', (req, res) => {
  res.sendFile(path.join(__dirname, '../frontend/build', 'index.html'));
});

// 404 for all other routes
app.get('*', (req, res) => {
  res.status(404).send('Not Found');
});

// Start server
async function startServer() {
  await initDB();
  
  app.listen(PORT, () => {
    console.log(`W Corp Cyber Range Server running on port ${PORT}`);
    console.log('Vulnerabilities enabled for educational purposes');
  });
}

startServer().catch(console.error);
