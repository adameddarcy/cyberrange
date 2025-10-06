# W Corp Cyber Range

A comprehensive cyber security training platform designed to demonstrate OWASP Top 10 vulnerabilities and complete cyber kill chain attacks. This intentionally vulnerable web application serves as an educational platform for security training and penetration testing.

## ⚠️ Security Warning

**This application contains intentional vulnerabilities for educational purposes only. Do not deploy in production environments or use real personal information.**

## 🏗️ Architecture

The cyber range consists of:

- **Landing Page:** Clean introduction at the root URL
- **Training Application:** React.js vulnerable application at `/wcorp`
- **Backend API:** Node.js server with intentional security flaws
- **Database:** MySQL database with sample vulnerable data

📐 **Detailed Architecture:** See [DECOMPOSITION/](DECOMPOSITION/) folder for:
- C4 Model diagrams (Context, Container, Component)
- Data Flow diagrams
- Message Sequence diagrams
- Complete system decomposition

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose
- Git
- 2GB+ RAM (for building React frontend)

### Local Development

1. Clone the repository:
```bash
git clone <repository-url>
cd cyberrange
```

2. Start the environment:
```bash
docker-compose up -d
```

3. Access the application:
- **Landing Page:** http://localhost:3000
- **Training Environment:** http://localhost:3000/wcorp
- **Database:** localhost:3306

### Default Credentials

- **Admin:** `admin` / `admin123`
- **User:** `john.doe` / `password123`
- **User:** `jane.smith` / `qwerty`

## 🌐 Deployment

For production deployment (on DigitalOcean, AWS, etc.):

```bash
# Use the automated deployment script
cd deploy
./fresh-digitalocean-install.sh
```

See `deploy/README.md` for detailed deployment instructions.

## 🔍 OWASP Top 10 Vulnerabilities

### A01 - Broken Access Control (IDOR)

**Location:** `/wcorp/api/user/profile/:id`, `/wcorp/api/user/sensitive/:id`

**Description:** No authorization checks allow any authenticated user to access any user's data.

**Exploitation:**
1. Login at `/wcorp/login`
2. Navigate to `/wcorp/portal/profile/1` (admin profile)
3. Change the ID parameter to access other users' profiles

**Example:**
```bash
# Access admin profile as regular user
curl -H "Authorization: Bearer <token>" http://localhost:3000/wcorp/api/user/profile/1

# Access sensitive data
curl -H "Authorization: Bearer <token>" http://localhost:3000/wcorp/api/user/sensitive/1
```

### A02 - Cryptographic Failures

**Location:** User registration and authentication system

**Description:** Passwords are stored in plain text without hashing or encryption.

**Exploitation:**
1. Register a new user
2. Query the database to see plain text passwords
3. Demonstrates the risk of storing unencrypted credentials

**Database Query:**
```sql
-- Connect to database and view passwords
SELECT username, password, email FROM users;
```

**Impact:** All user passwords are visible in plain text in the database.

### A03 - Injection (Parameter Tampering)

**Location:** Various API endpoints with user-supplied input

**Description:** Insufficient input validation and parameter tampering vulnerabilities.

**Exploitation:**
1. Manipulate URL parameters and request bodies
2. Test for SQL injection in search and filter endpoints
3. Bypass authentication checks through parameter manipulation

**Example:**
```bash
# Test parameter tampering
curl "http://localhost:3000/wcorp/api/user/notes/1?role=admin"

# Modify request parameters
curl -X POST http://localhost:3000/wcorp/api/register \
  -d '{"username":"test","password":"test","role":"admin"}'
```

### A05 - Security Misconfiguration

**Location:** Multiple configuration issues throughout the application

**Description:** Sensitive configuration files and information are exposed.

**Exploitation:**
1. Access exposed configuration:
   - `http://localhost:3000/.env`
   - `http://localhost:3000/package.json`

2. Check `robots.txt` and `sitemap.xml` for directory structure

3. Explore publicly accessible uploads directory

**Example:**
```bash
curl http://localhost:3000/.env
curl http://localhost:3000/package.json
curl http://localhost:3000/robots.txt
```

### A07 - Identification and Authentication Failures

**Location:** Login and session management

**Description:** Weak authentication mechanisms and predictable session tokens.

**Exploitation:**
1. Attempt brute force attacks (no rate limiting)
2. Analyze session token patterns
3. Test for session fixation and hijacking

**Example:**
```bash
# Brute force attempt (no rate limiting)
for pass in password123 admin123 test123; do
  curl -X POST http://localhost:3000/wcorp/api/login \
    -d "{\"username\":\"admin\",\"password\":\"$pass\"}"
done
```

### A08 - Software and Data Integrity Failures

**Location:** File upload functionality

**Description:** Unrestricted file upload without proper validation.

**Exploitation:**
1. Upload malicious files
2. Test for path traversal in file uploads
3. Attempt to upload executable content

**Example:**
```bash
# Upload a test file
curl -X POST http://localhost:3000/wcorp/api/upload \
  -F "file=@test.txt" \
  -H "Authorization: Bearer <token>"
```

### A10 - Server-Side Request Forgery (SSRF)

**Location:** `/api/fetch-url` endpoint

**Description:** No URL validation allows internal network access.

**Exploitation:**
1. Use the SSRF endpoint to access internal resources
2. Probe internal network services
3. Access cloud metadata endpoints

**Example:**
```bash
# Access internal resources
curl "http://localhost:3000/wcorp/api/fetch-url?url=http://localhost:3306"

# Try to access cloud metadata (if deployed on cloud)
curl "http://localhost:3000/wcorp/api/fetch-url?url=http://169.254.169.254/latest/meta-data/"
```

## 🎯 Cyber Kill Chain Demonstration

### Complete Attack Scenario

1. **Reconnaissance**
   - Analyze `robots.txt` and `sitemap.xml`
   - Examine HTML source code for comments
   - Identify exposed configuration files
   - Map application structure

2. **Weaponization**
   - Prepare injection payloads
   - Craft IDOR attack vectors
   - Develop session hijacking tools

3. **Delivery**
   - Upload malicious files
   - Inject payloads through forms
   - Send crafted API requests

4. **Exploitation**
   - Execute IDOR attacks to access admin data
   - Bypass authentication
   - Extract sensitive information

5. **Installation**
   - Establish persistent access
   - Create backdoor accounts
   - Modify application behavior

6. **Command & Control**
   - Maintain access through compromised accounts
   - Use SSRF for internal network access

7. **Actions on Objectives**
   - Extract all user data
   - Dump database contents
   - Access internal systems

### Step-by-Step Attack Flow

```bash
# 1. Reconnaissance
curl http://localhost:3000/robots.txt
curl http://localhost:3000/sitemap.xml
curl http://localhost:3000/.env

# 2. Information Gathering
curl http://localhost:3000/package.json

# 3. Authentication Bypass Attempt
curl -X POST http://localhost:3000/wcorp/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'

# 4. IDOR Exploitation
curl -H "Authorization: Bearer <token>" \
  http://localhost:3000/wcorp/api/user/profile/1

# 5. Data Exfiltration
curl -H "Authorization: Bearer <token>" \
  http://localhost:3000/wcorp/api/user/sensitive/1
```

## 🛠️ Development

### Project Structure

```
cyberrange/
├── backend/                  # Node.js API server
│   ├── server.js            # Main server file
│   ├── config/              # Configuration files
│   ├── middleware/          # Express middleware
│   └── routes/              # API routes
├── frontend/                # React application
│   ├── src/
│   │   ├── components/      # React components
│   │   ├── pages/           # Page components
│   │   └── contexts/        # React contexts
│   ├── public/
│   │   └── index-landing.html  # Landing page
│   └── build/               # Production build (generated)
├── database/
│   └── init.sql             # Database initialization
├── deploy/                  # Deployment scripts
│   ├── fresh-digitalocean-install.sh
│   └── README.md
├── docker-compose.yml       # Local development setup
└── docker-compose.simple.yml # Production setup
```

### Building from Source

**Frontend:**
```bash
cd frontend
npm install
npm run build
```

**Backend:**
```bash
cd backend
npm install
node server.js
```

### Database Schema

The database includes:
- `users` - User accounts with plain text passwords
- `sessions` - Session management
- `files` - File upload tracking
- `sensitive_data` - Intentionally exposed sensitive information
- `internal_notes` - Private user notes (vulnerable to IDOR)

## 🔒 Security Considerations

### For Educational Use Only

This cyber range is designed for:
- Security training and education
- Penetration testing practice
- Vulnerability assessment training
- Cyber kill chain demonstration
- OWASP Top 10 learning

### Not for Production

Do not use this application in production because:
- All vulnerabilities are intentional
- No security controls are implemented
- Sensitive data handling is deliberately insecure
- Authentication is purposely weak
- Input validation is intentionally missing

## 📚 Learning Objectives

After completing this cyber range, participants will understand:

1. **OWASP Top 10 Vulnerabilities**
   - How each vulnerability works
   - Common exploitation techniques
   - Real-world impact and consequences

2. **Cyber Kill Chain**
   - Complete attack lifecycle
   - How vulnerabilities chain together
   - Attack progression and escalation

3. **Defense Strategies**
   - How to prevent each vulnerability
   - Security best practices
   - Defense in depth principles
   - Proper input validation
   - Secure authentication mechanisms

## 🎓 Training Modules

### Module 1: Reconnaissance
- Information disclosure
- Directory enumeration
- Configuration exposure

### Module 2: Authentication Attacks
- Brute force attacks
- Session hijacking
- Credential stuffing

### Module 3: Authorization Bypass
- IDOR attacks
- Privilege escalation
- Access control bypass

### Module 4: Injection Attacks
- Parameter tampering
- Command injection concepts
- Input validation failures

### Module 5: Data Exfiltration
- Sensitive data exposure
- Database enumeration
- Information leakage

## 🤝 Contributing

This cyber range is designed for educational purposes. Contributions that enhance the learning experience are welcome:

1. Fork the repository
2. Create a feature branch
3. Add new vulnerabilities or training scenarios
4. Update documentation
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For questions or issues:

1. Check the documentation
2. Review the deployment guide in `/deploy/README.md`
3. Examine the source code
4. Create an issue for bugs or improvements

## 🔗 Additional Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Cyber Kill Chain](https://www.lockheedmartin.com/en-us/capabilities/cyber/cyber-kill-chain.html)
- [Docker Documentation](https://docs.docker.com/)
- [React Documentation](https://reactjs.org/)
- [Node.js Documentation](https://nodejs.org/)

---

**Remember: This is a cyber range for educational purposes only. Use responsibly and never deploy in production environments.**