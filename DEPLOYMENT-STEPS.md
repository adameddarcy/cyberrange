# Quick Deployment Steps for Server Update

## What Changed
- Added `"homepage": "/wcorp"` to `frontend/package.json`
- This ensures React builds assets with correct `/wcorp/` paths

## Steps to Deploy

### 1. Rebuild Frontend (After Node.js Update)
```bash
cd /Users/adam.darcy/code/cyberrange/frontend
npm run build
```

### 2. Upload Updated Files to Server
```bash
cd /Users/adam.darcy/code/cyberrange

# Upload the rebuilt frontend
scp -r frontend/build root@174.138.71.77:/opt/cyberrange/frontend/

# Upload the updated package.json
scp frontend/package.json root@174.138.71.77:/opt/cyberrange/frontend/

# Upload updated backend server.js (if needed)
scp backend/server.js root@174.138.71.77:/opt/cyberrange/backend/
```

### 3. Restart Containers on Server
```bash
# SSH into server
ssh root@174.138.71.77

# Navigate to app directory
cd /opt/cyberrange

# Restart the web container
docker restart deploy-web-1

# Or restart all containers
docker-compose restart
```

### 4. Verify
```bash
# Test the app
curl http://127.0.0.1:3000/wcorp/

# Should see the React app HTML, not "Not Found"
```

### 5. Test in Browser
Visit: http://174.138.71.77/wcorp

Should now load without 404 errors for JavaScript files.

---

## Alternative: Build in Docker Locally (If Node Issues Persist)

```bash
cd /Users/adam.darcy/code/cyberrange

docker run --rm \
  -v "$(pwd)/frontend:/app" \
  -w /app \
  node:16-alpine \
  sh -c "npm install && npm run build"
```

Then proceed with step 2 above.

---

## Troubleshooting

### If React app still shows 404:
```bash
# SSH to server
ssh root@174.138.71.77

# Check if build directory exists
ls -la /opt/cyberrange/frontend/build/

# Check if files are there
ls -la /opt/cyberrange/frontend/build/static/js/

# Restart container
docker restart deploy-web-1

# Check logs
docker logs deploy-web-1 --tail 50
```

### If homepage path is wrong:
The build output should say:
```
The project was built assuming it is hosted at /wcorp/.
```

If it says hosted at `/`, rebuild after confirming `package.json` has `"homepage": "/wcorp"`.

