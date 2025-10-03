-- W Corp Database Initialization Script
-- This script creates the database structure for the cyber range

USE wcorp_db;

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,  -- Stored in plain text (A02: Cryptographic Failures)
    email VARCHAR(100) UNIQUE NOT NULL,
    role ENUM('user', 'admin') DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Create sessions table for predictable session tokens (A07: Identification and Authentication Failures)
CREATE TABLE IF NOT EXISTS sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    token VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP + INTERVAL 24 HOUR),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create files table for file upload tracking
CREATE TABLE IF NOT EXISTS files (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    filename VARCHAR(255) NOT NULL,
    original_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size INT NOT NULL,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Insert initial users with weak passwords (A02: Cryptographic Failures)
INSERT INTO users (username, password, email, role) VALUES
('admin', 'admin123', 'admin@wcorp.com', 'admin'),
('john.doe', 'password123', 'john.doe@wcorp.com', 'user'),
('jane.smith', 'qwerty', 'jane.smith@wcorp.com', 'user'),
('bob.wilson', '123456', 'bob.wilson@wcorp.com', 'user'),
('alice.brown', 'welcome', 'alice.brown@wcorp.com', 'user');

-- Insert some sample files
INSERT INTO files (user_id, filename, original_name, file_path, file_size) VALUES
(1, 'admin_document.pdf', 'admin_document.pdf', '/uploads/admin_document.pdf', 1024),
(2, 'john_report.docx', 'john_report.docx', '/uploads/john_report.docx', 2048),
(3, 'jane_presentation.pptx', 'jane_presentation.pptx', '/uploads/jane_presentation.pptx', 4096);

-- Create a table for sensitive data that should be protected
CREATE TABLE IF NOT EXISTS sensitive_data (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    data_type VARCHAR(50) NOT NULL,
    data_value TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Insert sensitive data
INSERT INTO sensitive_data (user_id, data_type, data_value) VALUES
(1, 'ssn', '123-45-6789'),
(1, 'credit_card', '4532-1234-5678-9012'),
(2, 'ssn', '987-65-4321'),
(2, 'bank_account', '1234567890'),
(3, 'ssn', '555-44-3333'),
(3, 'credit_card', '5555-4444-3333-2222');

-- Create a table for internal notes (should be protected from IDOR)
CREATE TABLE IF NOT EXISTS internal_notes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    note TEXT NOT NULL,
    is_confidential BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Insert internal notes
INSERT INTO internal_notes (user_id, note, is_confidential) VALUES
(1, 'Admin note: System maintenance scheduled for next week', TRUE),
(2, 'John needs additional training on security protocols', FALSE),
(3, 'Jane has been promoted to senior developer', TRUE),
(4, 'Bob is on probation for security violations', TRUE),
(5, 'Alice is our new security consultant', FALSE);
