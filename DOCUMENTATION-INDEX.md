# W Corp Cyber Range - Documentation Index

## 📚 Complete Documentation Guide

All documentation has been updated and verified as of October 6, 2025.

---

## 🚀 Getting Started

### [README.md](README.md)
**Main documentation** - Start here!
- Quick start guide
- Architecture overview  
- Setup instructions
- API endpoints reference
- Deployment information

---

## 🎯 Vulnerability Guides

### [VULNERABILITY-GUIDE.md](VULNERABILITY-GUIDE.md) ⭐ MAIN GUIDE
**Comprehensive server-side vulnerability documentation**

Covers 8 OWASP Top 10 vulnerabilities:
1. **A01** - Broken Access Control (IDOR)
2. **A02** - Cryptographic Failures (Plain text passwords)
3. **A03** - Parameter Tampering
4. **A03** - SQL Injection ⭐ NEW & UPDATED
5. **A05** - Security Misconfiguration
6. **A07** - Authentication Failures
7. **A08** - File Upload Vulnerabilities
8. **A10** - Server-Side Request Forgery (SSRF)

Each section includes:
- ✅ Step-by-step exploitation
- ✅ Complete code examples
- ✅ Vulnerable code snippets
- ✅ Secure code fixes
- ✅ Impact assessment
- ✅ Learning objectives

---

### [SQL-INJECTION-CHEATSHEET.md](SQL-INJECTION-CHEATSHEET.md) ⭐ NEW
**Quick reference for SQL injection attacks**

- 🎯 Working authentication bypass commands
- 💎 Data extraction techniques
- 🌐 Browser-based exploitation
- 🐍 Python automation scripts
- ⚠️ Common errors and fixes
- 📊 Database schema reference

**Perfect for:** Quick copy-paste commands, testing, demonstrations

---

### [UI-ATTACKS-GUIDE.md](UI-ATTACKS-GUIDE.md) ⭐ NEW
**Complete client-side attack guide**

Covers 6 UI-based vulnerabilities:
1. **Cross-Site Scripting (XSS)** - 6 variants
2. **Cross-Site Request Forgery (CSRF)** - 4 techniques
3. **Clickjacking** - 3 methods
4. **DOM-Based Vulnerabilities**
5. **Session Storage Attacks**
6. **Browser DevTools Exploitation**

Each attack includes:
- ✅ Exploitation steps
- ✅ Malicious code examples
- ✅ Defense mechanisms
- ✅ Real-world scenarios

---

### [ATTACK-SUMMARY.md](ATTACK-SUMMARY.md) ⭐ NEW
**Quick reference for all attacks**

- 📋 Complete attack inventory (14 vulnerabilities)
- 🚀 Quick start attack scenarios
- 🎓 Training paths (4 progressive paths)
- 🔧 Essential tools list
- 📊 Difficulty ratings
- 🎮 Challenge mode
- 📈 Progress tracking checklist

**Perfect for:** Planning training sessions, tracking progress, quick lookup

---

## 📐 Architecture & Design

### [DECOMPOSITION/](DECOMPOSITION/) ⭐ NEW
**Complete system architecture documentation**

Contains 15 detailed diagrams:
- **C4 Model**: Context, Container, Component diagrams
- **Data Flow**: 6 detailed flow diagrams showing attack paths
- **Sequence Diagrams**: 6 temporal interaction diagrams

**Perfect for:** Understanding system architecture, teaching attacks, security assessments

---

## 🎓 Training Materials

### [cyber-kill-chain.md](cyber-kill-chain.md)
**Attack progression framework**
- Maps attacks to cyber kill chain stages
- Shows how to chain vulnerabilities
- Complete attack scenarios
- Defensive strategies

**Updated:** Removed PHP references, updated for current architecture

---

## 🔧 Deployment & Setup

### [DEPLOYMENT-STEPS.md](DEPLOYMENT-STEPS.md) ⭐ NEW
**Quick deployment guide for server updates**
- Frontend rebuild instructions
- File upload commands
- Container restart procedures
- Troubleshooting steps

---

### [deployment-guide.md](deployment-guide.md)
**Comprehensive deployment documentation**
- Security considerations
- Platform options (DigitalOcean, AWS)
- Production configuration
- Network isolation strategies

---

## 📝 Change Logs

### [CHANGES.md](CHANGES.md)
**Complete refactoring documentation**
- All architectural changes
- Removed features (PHP components)
- New structure (/wcorp base URL)
- Migration notes

---

## 🔑 Key Updates (October 2025)

### ✅ Fixed
- All SQL injection examples now use correct API paths (`/api` not `/wcorp/api`)
- Added space after SQL comment markers (`-- `) for proper syntax
- Updated all curl commands to use 7-column UNION SELECT for users table
- Corrected JSON response examples to match actual database schema

### ⭐ New Documentation
- **SQL-INJECTION-CHEATSHEET.md** - Quick reference with working commands
- **UI-ATTACKS-GUIDE.md** - Complete client-side attack guide
- **ATTACK-SUMMARY.md** - All-in-one vulnerability reference
- **DEPLOYMENT-STEPS.md** - Quick deployment procedures

### 🔄 Updated
- **VULNERABILITY-GUIDE.md** - Fixed all SQL injection examples
- **README.md** - Updated for /wcorp architecture
- **cyber-kill-chain.md** - Removed PHP references

---

## 🎯 Documentation by Use Case

### I want to learn about a specific vulnerability
→ [VULNERABILITY-GUIDE.md](VULNERABILITY-GUIDE.md) or [UI-ATTACKS-GUIDE.md](UI-ATTACKS-GUIDE.md)

### I need quick commands for SQL injection
→ [SQL-INJECTION-CHEATSHEET.md](SQL-INJECTION-CHEATSHEET.md)

### I want an overview of all attacks
→ [ATTACK-SUMMARY.md](ATTACK-SUMMARY.md)

### I need to set up the environment
→ [README.md](README.md)

### I want to deploy to production
→ [deployment-guide.md](deployment-guide.md)

### I need to understand the attack chain
→ [cyber-kill-chain.md](cyber-kill-chain.md)

### I'm troubleshooting deployment issues
→ [DEPLOYMENT-STEPS.md](DEPLOYMENT-STEPS.md)

---

## 📊 Documentation Statistics

- **Total Guides:** 10
- **Vulnerabilities Covered:** 14 (8 server-side, 6 client-side)
- **Code Examples:** 100+
- **Attack Scenarios:** 30+
- **Lines of Documentation:** ~4,500

---

## 🔗 Quick Links

### Training Paths
1. [Beginner Path](ATTACK-SUMMARY.md#path-1-web-application-security-basics)
2. [Injection Attacks Path](ATTACK-SUMMARY.md#path-2-injection-attacks)
3. [Client-Side Security Path](ATTACK-SUMMARY.md#path-3-client-side-security)
4. [Advanced Exploitation Path](ATTACK-SUMMARY.md#path-4-advanced-exploitation)

### Most Common Attacks
- [SQL Injection - Auth Bypass](SQL-INJECTION-CHEATSHEET.md#authentication-bypass-easiest)
- [IDOR - Access Other Profiles](VULNERABILITY-GUIDE.md#a01---broken-access-control-idor)
- [Environment File Disclosure](VULNERABILITY-GUIDE.md#a05---security-misconfiguration)
- [XSS via File Upload](UI-ATTACKS-GUIDE.md#cross-site-scripting-xss)

---

## 💡 Tips for Using This Documentation

1. **Start with ATTACK-SUMMARY.md** for an overview
2. **Use SQL-INJECTION-CHEATSHEET.md** for quick testing
3. **Refer to VULNERABILITY-GUIDE.md** for deep dives
4. **Check UI-ATTACKS-GUIDE.md** for client-side attacks
5. **Follow cyber-kill-chain.md** for realistic attack scenarios

---

## ⚠️ Important Notes

### API Paths
- React app is served at: `/wcorp`
- API endpoints are at: `/api` (NOT `/wcorp/api`)
- Landing page is at: `/` (root)

### SQL Injection Syntax
- Always add space after `--` comment: `admin'-- ` (note the space!)
- Users table has 7 columns: `id, username, password, email, role, created_at, updated_at`

### Common Errors
See [SQL-INJECTION-CHEATSHEET.md - Common Errors](SQL-INJECTION-CHEATSHEET.md#common-errors--fixes)

---

## 🤝 Contributing

If you find errors in the documentation:
1. Check the [SQL-INJECTION-CHEATSHEET.md](SQL-INJECTION-CHEATSHEET.md) for correct syntax
2. Verify API paths (use `/api`, not `/wcorp/api`)
3. Test commands against the live environment
4. Update relevant documentation files

---

## 📜 License & Legal

This documentation is for **educational purposes only**. All vulnerabilities are intentional and designed for security training in a controlled environment.

**⚠️ Never use these techniques on systems you don't own or have explicit written permission to test.**

---

© 2025 W Corp Cyber Range - Educational Security Training Platform

**Last Updated:** October 6, 2025

