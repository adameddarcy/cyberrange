# Cyber Range Refactoring - Changes Summary

## Overview
This document outlines all changes made to refactor the W Corp Cyber Range application to remove PHP components and reorganize the structure.

## Major Changes

### 1. Application Structure Reorganization

**Before:**
- Root (`/`) served React application directly
- PHP files at `/php/` directory
- Legacy HTML files mixed with React app

**After:**
- Root (`/`) serves a clean landing page explaining the cyber range
- Training environment at `/wcorp/` (React application)
- All PHP components removed
- Cleaner separation of concerns

### 2. Files Removed

- `/php/` directory (entire directory deleted)
  - `index.php`
  - `login.php`
  - `upload.php`
  - `info.php`
  - All PHP-related files

- `Dockerfile.php` (no longer needed)

### 3. Files Created

- `/frontend/public/index-landing.html` - New landing page with:
  - Professional design
  - Clear explanation of cyber range purpose
  - Security warnings
  - Link to training environment at `/wcorp`

### 4. Files Modified

#### Backend (`/backend/server.js`)
- Changed static file serving from root to `/wcorp`
- Added landing page route at root (`/`)
- Updated catch-all routes to properly handle `/wcorp` paths
- Removed PHP-related route handlers
- Updated uploads directory path

**Key Changes:**
```javascript
// Before:
app.use(express.static(path.join(__dirname, '../frontend/build')));

// After:
app.use('/wcorp', express.static(path.join(__dirname, '../frontend/build')));

// Added:
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, '../frontend/public', 'index-landing.html'));
});

app.get('/wcorp/*', (req, res) => {
  res.sendFile(path.join(__dirname, '../frontend/build', 'index.html'));
});
```

#### Frontend (`/frontend/src/App.js`)
- Added `basename="/wcorp"` to Router component
- All React routes now properly scoped to `/wcorp` path

**Key Change:**
```javascript
// Before:
<Router>

// After:
<Router basename="/wcorp">
```

### 5. Documentation Updates

#### Main README.md
- Removed all PHP vulnerability references
- Updated OWASP Top 10 sections to remove SQL injection via PHP
- Removed PHP-related exploitation examples
- Updated application architecture description
- Added new URL structure documentation
- Updated Quick Start guide
- Removed PHP-specific attack vectors

**Removed Vulnerabilities:**
- A03 - SQL Injection via PHP login form
- A08 - File upload via PHP upload.php
- PHP-specific exploitation techniques

**Updated Structure:**
```
Before: 
- Frontend: React
- Backend: Node.js
- Legacy: PHP
- Database: MySQL

After:
- Landing Page: Static HTML at root
- Training Environment: React at /wcorp
- Backend: Node.js API
- Database: MySQL
```

#### cyber-kill-chain.md
- Complete rewrite without PHP dependencies
- Updated all examples to use Node.js API endpoints
- Removed web shell upload demonstrations
- Removed PHP-specific exploitation techniques
- Updated reconnaissance paths
- Modified delivery and exploitation stages
- New complete attack chain example using only Node.js vulnerabilities

#### deploy/README.md
- Updated file listing
- Removed PHP deployment references
- Clarified deployment structure

### 6. URL Structure Changes

#### Before:
```
http://your-server/           → React app
http://your-server/login      → React login
http://your-server:8080/      → PHP legacy system
http://your-server:8080/login.php → PHP login
```

#### After:
```
http://your-server/           → Landing page
http://your-server/wcorp/     → React training environment
http://your-server/wcorp/login → React login
http://your-server/wcorp/api/ → Backend API
```

## Remaining Vulnerabilities

The following OWASP Top 10 vulnerabilities are still demonstrated:

1. **A01 - Broken Access Control (IDOR)**
   - Location: `/wcorp/api/user/profile/:id`
   - No authorization checks on user data access

2. **A02 - Cryptographic Failures**
   - Location: User authentication system
   - Plain text password storage

3. **A03 - Injection (Parameter Tampering)**
   - Location: Various API endpoints
   - Insufficient input validation

4. **A05 - Security Misconfiguration**
   - Location: `/.env`, `/package.json`
   - Exposed configuration files

5. **A07 - Authentication Failures**
   - Location: Login system
   - Weak authentication, no rate limiting

6. **A08 - Software and Data Integrity Failures**
   - Location: File upload functionality
   - Unrestricted file uploads

7. **A10 - Server-Side Request Forgery (SSRF)**
   - Location: `/api/fetch-url`
   - No URL validation

## Migration Guide

### For Existing Deployments

If you have an existing deployment, follow these steps:

1. **Backup your current deployment:**
   ```bash
   docker-compose down
   tar -czf backup-$(date +%Y%m%d).tar.gz /opt/cyberrange
   ```

2. **Pull latest changes:**
   ```bash
   cd /opt/cyberrange
   git pull origin main
   ```

3. **Rebuild frontend:**
   ```bash
   cd frontend
   docker run --rm -v $(pwd):/app -w /app node:16-alpine sh -c "npm install && npm run build"
   ```

4. **Upload to server:**
   ```bash
   scp -r build root@your-server:/opt/cyberrange/frontend/
   scp backend/server.js root@your-server:/opt/cyberrange/backend/
   scp frontend/public/index-landing.html root@your-server:/opt/cyberrange/frontend/public/
   ```

5. **Restart containers:**
   ```bash
   docker-compose restart web
   ```

6. **Test new structure:**
   - Root: http://your-server/ (should show landing page)
   - Training: http://your-server/wcorp/ (should show React app)

### For New Deployments

Use the updated deployment script:
```bash
./deploy/fresh-digitalocean-install.sh
```

## Testing Checklist

- [ ] Root URL (`/`) shows landing page
- [ ] `/wcorp/` redirects to `/wcorp/login` or landing
- [ ] `/wcorp/login` shows login page
- [ ] Login functionality works at `/wcorp/api/login`
- [ ] IDOR vulnerability still works at `/wcorp/api/user/profile/:id`
- [ ] Configuration exposure still works at `/.env`
- [ ] File upload works at `/wcorp/api/upload`
- [ ] SSRF vulnerability still works at `/api/fetch-url`
- [ ] Admin panel accessible at `/wcorp/admin`
- [ ] All API endpoints respond correctly

## Breaking Changes

1. **URLs Changed:** All React app routes now require `/wcorp` prefix
2. **PHP Removed:** No PHP vulnerabilities available
3. **Port Changes:** No longer need port 8080 (PHP was removed)
4. **Docker Compose:** PHP service removed from docker-compose files

## Benefits of Changes

1. **Cleaner Architecture:** Clear separation between landing and training
2. **Simpler Deployment:** No PHP dependencies to manage
3. **Better User Experience:** Professional landing page explains purpose
4. **Easier Maintenance:** One technology stack (Node.js + React)
5. **Updated Documentation:** All docs reflect current structure
6. **No PHP Complexity:** Easier to understand and modify

## Next Steps

1. Test all functionality in the new structure
2. Update any custom scripts or tools to use new URLs
3. Inform training participants of new URL structure
4. Monitor for any issues with the new setup

## Rollback Plan

If needed, rollback to previous version:

```bash
# Restore from backup
cd /opt
rm -rf cyberrange
tar -xzf backup-YYYYMMDD.tar.gz

# Restart with old config
cd cyberrange
docker-compose up -d
```

## Support

For issues or questions:
1. Check this document
2. Review updated README.md
3. Test with provided examples
4. Check deployment logs

---

**Date of Changes:** October 6, 2025  
**Version:** 2.0.0  
**Status:** Complete
