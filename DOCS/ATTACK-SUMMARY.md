# W Corp Cyber Range - Attack Surface Summary

## 🎯 Quick Reference Guide

This document provides a quick overview of all vulnerabilities and attack vectors available in the W Corp Cyber Range training environment.

---

## 📋 Complete Attack Inventory

### Server-Side Attacks

| # | Vulnerability | OWASP | Endpoints | Difficulty | Impact | Guide |
|---|--------------|-------|-----------|------------|--------|-------|
| 1 | **Broken Access Control (IDOR)** | A01 | `/api/user/profile/:id` | Easy | High | [VULNERABILITY-GUIDE.md](VULNERABILITY-GUIDE.md#a01---broken-access-control-idor) |
| 2 | **Plain Text Passwords** | A02 | `/api/register`, `/api/login` | Easy | Critical | [VULNERABILITY-GUIDE.md](VULNERABILITY-GUIDE.md#a02---cryptographic-failures) |
| 3 | **Parameter Tampering** | A03 | `/api/register`, `/api/user/update` | Easy | High | [VULNERABILITY-GUIDE.md](VULNERABILITY-GUIDE.md#a03---injection-parameter-tampering) |
| 4 | **SQL Injection** | A03 | `/api/legacy-login`, `/api/search` | Medium | Critical | [VULNERABILITY-GUIDE.md](VULNERABILITY-GUIDE.md#a03---sql-injection) |
| 5 | **Environment File Exposure** | A05 | `/.env` | Very Easy | Critical | [VULNERABILITY-GUIDE.md](VULNERABILITY-GUIDE.md#a05---security-misconfiguration) |
| 6 | **Predictable Session Tokens** | A07 | `/api/login` | Medium | High | [VULNERABILITY-GUIDE.md](VULNERABILITY-GUIDE.md#a07---identification-and-authentication-failures) |
| 7 | **Unrestricted File Upload** | A08 | `/api/upload` | Medium | Critical | [VULNERABILITY-GUIDE.md](VULNERABILITY-GUIDE.md#a08---software-and-data-integrity-failures) |
| 8 | **Server-Side Request Forgery** | A10 | `/api/fetch-url` | Easy | High | [VULNERABILITY-GUIDE.md](VULNERABILITY-GUIDE.md#a10---server-side-request-forgery-ssrf) |

### Client-Side/UI Attacks

| # | Vulnerability | Type | Attack Vector | Difficulty | Impact | Guide |
|---|--------------|------|---------------|------------|--------|-------|
| 9 | **Stored XSS** | XSS | Username field, profile data | Easy | High | [UI-ATTACKS-GUIDE.md](UI-ATTACKS-GUIDE.md#cross-site-scripting-xss) |
| 10 | **File-Based XSS** | XSS | HTML/SVG file uploads | Medium | Critical | [UI-ATTACKS-GUIDE.md](UI-ATTACKS-GUIDE.md#cross-site-scripting-xss) |
| 11 | **CSRF** | CSRF | All POST endpoints | Easy | High | [UI-ATTACKS-GUIDE.md](UI-ATTACKS-GUIDE.md#cross-site-request-forgery-csrf) |
| 12 | **Clickjacking** | Clickjacking | Iframe embedding | Easy | Medium | [UI-ATTACKS-GUIDE.md](UI-ATTACKS-GUIDE.md#clickjacking) |
| 13 | **Session Token Theft** | Storage | Browser DevTools/Console | Very Easy | Critical | [UI-ATTACKS-GUIDE.md](UI-ATTACKS-GUIDE.md#session-storage-attacks) |
| 14 | **DOM-Based XSS** | XSS | URL parameters, hash | Medium | High | [UI-ATTACKS-GUIDE.md](UI-ATTACKS-GUIDE.md#dom-based-vulnerabilities) |

---

## 🚀 Quick Start Attack Scenarios

### Scenario 1: Complete Account Takeover (Beginner)
**Time:** 5 minutes | **Tools:** Browser, curl

1. Access `http://localhost:3000/.env` to get database credentials
2. Use IDOR to view admin profile: `/wcorp/api/user/profile/1`
3. Open browser console and steal JWT token: `localStorage.getItem('token')`
4. Use token to access admin endpoints

**Skills Learned:** Information disclosure, broken access control, session management

---

### Scenario 2: SQL Injection to Admin (Intermediate)
**Time:** 10 minutes | **Tools:** curl or Postman

1. Test SQL injection on `/wcorp/api/legacy-login`
2. Bypass authentication with `admin'--`
3. Extract all user data using UNION SELECT
4. Login with discovered admin credentials

**Skills Learned:** SQL injection, authentication bypass, data extraction

---

### Scenario 3: XSS + Cookie Stealing (Intermediate)
**Time:** 10 minutes | **Tools:** Browser, text editor

1. Register user with XSS payload in username
2. Upload malicious HTML file with JavaScript
3. Share link with victim to steal their session
4. Use stolen session to access their account

**Skills Learned:** XSS, session hijacking, social engineering

---

### Scenario 4: Full System Compromise (Advanced)
**Time:** 20 minutes | **Tools:** curl, sqlmap, browser

1. Discover `.env` file via SSRF or direct access
2. Use SQL injection to create admin account
3. Upload web shell via file upload vulnerability
4. Execute system commands through web shell
5. Extract all database data
6. Pivot to other internal systems

**Skills Learned:** Chaining vulnerabilities, privilege escalation, persistence

---

## 🎓 Training Paths

### Path 1: Web Application Security Basics
1. ✅ Environment file exposure (A05)
2. ✅ IDOR vulnerability (A01)
3. ✅ Session token analysis (A07)
4. ✅ Plain text password discovery (A02)

**Outcome:** Understand basic web app security concepts

---

### Path 2: Injection Attacks
1. ✅ Parameter tampering (A03)
2. ✅ SQL injection - Authentication bypass
3. ✅ SQL injection - Data extraction
4. ✅ SQL injection - Blind techniques

**Outcome:** Master injection vulnerabilities

---

### Path 3: Client-Side Security
1. ✅ Stored XSS via input fields
2. ✅ File-based XSS attacks
3. ✅ CSRF attack creation
4. ✅ Session storage exploitation
5. ✅ Clickjacking techniques

**Outcome:** Understand client-side attack vectors

---

### Path 4: Advanced Exploitation
1. ✅ Chaining SSRF with file disclosure
2. ✅ Unrestricted file upload to RCE
3. ✅ Privilege escalation via parameter tampering
4. ✅ Complete database compromise
5. ✅ Persistent backdoor installation

**Outcome:** Advanced penetration testing skills

---

## 🔧 Essential Tools

### Command Line
- **curl** - HTTP requests and API testing
- **sqlmap** - Automated SQL injection
- **jq** - JSON parsing and formatting

### Browser Tools
- **Developer Console** (F12) - JavaScript execution, storage inspection
- **Network Tab** - Request/response analysis
- **Application Tab** - Cookie and storage management

### Optional Tools
- **Burp Suite** - Web application security testing
- **Postman** - API testing and automation
- **Python** - Custom exploit scripts

---

## 📊 Difficulty Ratings

| Difficulty | Time Required | Prerequisites | Example Vulnerabilities |
|------------|---------------|---------------|-------------------------|
| **Very Easy** | 1-2 min | Basic browser skills | `.env` exposure, token theft |
| **Easy** | 5-10 min | HTTP basics, curl | IDOR, CSRF, basic XSS |
| **Medium** | 15-30 min | SQL knowledge, scripting | SQL injection, file upload, blind SQLi |
| **Hard** | 30-60 min | Advanced exploitation | Chained attacks, RCE, WAF bypass |

---

## 🎯 Learning Objectives by Vulnerability

### A01 - Broken Access Control
- [ ] Understand the difference between authentication and authorization
- [ ] Learn to test for IDOR vulnerabilities
- [ ] Practice object reference enumeration
- [ ] Implement proper access control checks

### A02 - Cryptographic Failures
- [ ] Recognize plain text password storage
- [ ] Understand password hashing (bcrypt, Argon2)
- [ ] Learn about salt and pepper
- [ ] Implement secure password storage

### A03 - Injection
- [ ] Identify injection points in applications
- [ ] Understand SQL query construction
- [ ] Learn parameterized queries
- [ ] Practice both manual and automated injection
- [ ] Understand parameter tampering risks

### A05 - Security Misconfiguration
- [ ] Learn about environment file security
- [ ] Understand configuration management
- [ ] Practice information gathering
- [ ] Implement secure file permissions

### A07 - Authentication Failures
- [ ] Analyze session token generation
- [ ] Understand JWT structure and vulnerabilities
- [ ] Learn about secure random generation
- [ ] Implement proper session management

### A08 - File Upload Vulnerabilities
- [ ] Understand file type validation bypass
- [ ] Learn about magic bytes and MIME types
- [ ] Practice web shell creation
- [ ] Implement secure file upload handling

### A10 - SSRF
- [ ] Understand server-side request risks
- [ ] Learn about internal network access
- [ ] Practice SSRF exploitation techniques
- [ ] Implement URL validation and whitelisting

### XSS (Cross-Site Scripting)
- [ ] Understand different XSS types (stored, reflected, DOM)
- [ ] Learn JavaScript injection techniques
- [ ] Practice cookie stealing and session hijacking
- [ ] Implement input sanitization and CSP

### CSRF (Cross-Site Request Forgery)
- [ ] Understand state-changing operations
- [ ] Learn about CSRF token implementation
- [ ] Practice crafting malicious requests
- [ ] Implement SameSite cookies

---

## 🚨 Safety Notice

**IMPORTANT:** All attacks documented here are for **educational purposes only** and should **ONLY** be performed in the W Corp Cyber Range training environment.

### ⚠️ Legal Warning
- Never test on systems you don't own or have explicit written permission to test
- Unauthorized access to computer systems is illegal in most jurisdictions
- These techniques are for defensive security training only

### ✅ Ethical Use
- Use this knowledge to build more secure applications
- Report vulnerabilities responsibly
- Help organizations improve their security posture
- Educate others about web security best practices

---

## 📚 Additional Resources

### Documentation
- **[VULNERABILITY-GUIDE.md](VULNERABILITY-GUIDE.md)** - Detailed server-side vulnerability guide
- **[UI-ATTACKS-GUIDE.md](UI-ATTACKS-GUIDE.md)** - Client-side attack techniques
- **[README.md](README.md)** - Setup and architecture documentation
- **[cyber-kill-chain.md](cyber-kill-chain.md)** - Attack progression framework

### External Resources
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [PortSwigger Web Security Academy](https://portswigger.net/web-security)
- [HackTheBox](https://www.hackthebox.com/)
- [OWASP WebGoat](https://owasp.org/www-project-webgoat/)

---

## 🎮 Challenge Mode

### Beginner Challenges
1. [ ] Find and access the `.env` file
2. [ ] Access another user's profile
3. [ ] Login without knowing any passwords
4. [ ] Steal a session token from the browser
5. [ ] Upload a file with any extension

### Intermediate Challenges
1. [ ] Extract all passwords from the database
2. [ ] Create an admin account via parameter tampering
3. [ ] Inject XSS that steals cookies
4. [ ] Perform a successful CSRF attack
5. [ ] Use SSRF to read internal files

### Advanced Challenges
1. [ ] Complete authentication bypass via SQL injection
2. [ ] Chain IDOR + XSS for account takeover
3. [ ] Upload and execute a web shell
4. [ ] Extract data using blind SQL injection
5. [ ] Perform a complete system compromise from zero knowledge

---

## 📈 Progress Tracking

Track your learning progress:

```markdown
### My Training Progress

**Server-Side Attacks:**
- [ ] A01 - Broken Access Control (IDOR)
- [ ] A02 - Cryptographic Failures
- [ ] A03 - Parameter Tampering
- [ ] A03 - SQL Injection
- [ ] A05 - Security Misconfiguration
- [ ] A07 - Authentication Failures
- [ ] A08 - File Upload Vulnerabilities
- [ ] A10 - SSRF

**Client-Side Attacks:**
- [ ] Stored XSS
- [ ] File-Based XSS
- [ ] CSRF
- [ ] Clickjacking
- [ ] Session Token Theft
- [ ] DOM-Based XSS

**Advanced Skills:**
- [ ] Vulnerability chaining
- [ ] Web shell deployment
- [ ] Blind SQL injection
- [ ] Complete system compromise
```

---

© 2025 W Corp Cyber Range - Educational Security Training Platform

