<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>W Corp - PHP Legacy System</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
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
        .alert-warning {
            background-color: #fff3cd;
            color: #856404;
            border: 1px solid #ffeaa7;
        }
        .alert-danger {
            background-color: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
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
        .btn-danger {
            background-color: #e74c3c;
        }
        .btn-danger:hover {
            background-color: #c0392b;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>W Corp - PHP Legacy System</h1>
            <p>Legacy PHP Components with Intentional Vulnerabilities</p>
        </div>

        <div class="nav">
            <a href="index.php">Home</a>
            <a href="login.php">SQL Injection Demo</a>
            <a href="upload.php">File Upload Demo</a>
            <a href="info.php">PHP Info</a>
        </div>

        <div class="alert alert-warning">
            <strong>⚠️ Security Warning:</strong> This is a cyber range environment with intentional vulnerabilities for educational purposes. 
            Do not use in production environments.
        </div>

        <h2>Welcome to W Corp PHP Legacy System</h2>
        <p>This system contains intentionally vulnerable PHP components that demonstrate various OWASP Top 10 vulnerabilities:</p>

        <h3>Available Vulnerabilities:</h3>
        <ul>
            <li><strong>A03 - Injection (SQL Injection):</strong> <a href="login.php">Login Form</a></li>
            <li><strong>A08 - Software and Data Integrity Failures:</strong> <a href="upload.php">File Upload</a></li>
            <li><strong>A05 - Security Misconfiguration:</strong> <a href="info.php">PHP Info</a></li>
        </ul>

        <h3>Cyber Kill Chain Demonstration:</h3>
        <ol>
            <li><strong>Reconnaissance:</strong> Explore the system and identify vulnerabilities</li>
            <li><strong>Weaponization:</strong> Create malicious files for upload</li>
            <li><strong>Delivery:</strong> Use file upload vulnerability to deliver payload</li>
            <li><strong>Exploitation:</strong> Execute the uploaded web shell</li>
            <li><strong>Installation:</strong> Establish persistent access</li>
            <li><strong>Command & Control:</strong> Use web shell for remote access</li>
            <li><strong>Actions on Objectives:</strong> Perform data exfiltration</li>
        </ol>

        <div class="alert alert-danger">
            <strong>🔴 Critical Vulnerabilities Present:</strong>
            <ul>
                <li>SQL Injection in login form</li>
                <li>Unrestricted file upload</li>
                <li>Exposed PHP configuration</li>
                <li>No input validation</li>
                <li>Weak file permissions</li>
            </ul>
        </div>

        <h3>Getting Started:</h3>
        <p>Begin your cyber range exercise by exploring the vulnerable components:</p>
        <div style="margin-top: 20px;">
            <a href="login.php" class="btn">Test SQL Injection</a>
            <a href="upload.php" class="btn">Test File Upload</a>
            <a href="info.php" class="btn btn-danger">View PHP Info</a>
        </div>
    </div>

    <!-- VULNERABILITY: Exposed internal information in HTML comments -->
    <!-- Database: MySQL on localhost:3306, user: wcorp_user, password: wcorp_pass, database: wcorp_db -->
    <!-- Upload directory: /var/www/html/uploads (permissions: 777) -->
    <!-- PHP version: 7.4 (known vulnerabilities) -->
    <!-- Apache version: 2.4 (default configuration) -->
</body>
</html>
