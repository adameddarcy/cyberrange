# C4 Model - Container Diagram

## Container Level

This diagram shows the high-level technology containers (applications, data stores) that make up the W Corp Cyber Range system.

```mermaid
C4Container
    title Container Diagram - W Corp Cyber Range

    Person(user, "User", "Security trainee or penetration tester")
    
    System_Boundary(wcorp, "W Corp Cyber Range") {
        Container(nginx, "Nginx", "Web Server", "Reverse proxy, serves static files, handles routing")
        Container(react, "React Frontend", "JavaScript/React", "Single Page Application, /wcorp base path")
        Container(landing, "Landing Page", "Static HTML", "Welcome page at root URL")
        Container(node, "Node.js Backend", "Express.js", "REST API with intentional vulnerabilities")
        ContainerDb(mysql, "MySQL Database", "MySQL 8.0", "Stores user data, sessions, files metadata (plain text passwords)")
        Container(uploads, "File Storage", "Filesystem", "Stores uploaded files")
    }
    
    Rel(user, nginx, "Visits", "HTTPS (443)")
    Rel(nginx, landing, "Serves root page", "HTTP")
    Rel(nginx, react, "Serves /wcorp/*", "HTTP")
    Rel(nginx, node, "Proxies /api/*", "HTTP (3000)")
    
    Rel(react, node, "Makes API calls", "JSON/HTTPS")
    Rel(node, mysql, "Reads/Writes data", "MySQL Protocol (3306)")
    Rel(node, uploads, "Stores/Retrieves files", "Filesystem")
    
    UpdateRelStyle(user, nginx, $textColor="blue", $lineColor="blue")
    UpdateRelStyle(react, node, $textColor="green", $lineColor="green")
    UpdateRelStyle(node, mysql, $textColor="orange", $lineColor="orange")
```

## Container Responsibilities

### Nginx (Reverse Proxy)
- Entry point for all HTTP/HTTPS traffic
- Routes `/` → Landing page
- Routes `/wcorp/*` → React SPA
- Proxies `/api/*` → Node.js backend
- Serves static assets

### React Frontend (/wcorp)
- Single Page Application
- User authentication UI
- User portal and admin portal
- File upload interface
- Demonstrates client-side vulnerabilities (XSS, CSRF)

### Landing Page (/)
- Static HTML welcome page
- Explains the cyber range purpose
- Links to training environment

### Node.js Backend (Express.js)
- REST API endpoints (`/api/*`)
- Authentication logic (weak/predictable)
- Database queries (includes SQL injection vulns)
- File upload handling (unrestricted)
- SSRF endpoint
- Contains ALL server-side vulnerabilities

### MySQL Database
- Stores user accounts (plain text passwords!)
- Session management
- File metadata
- Sensitive user data (SSNs, credit cards)
- Internal notes

### File Storage
- Uploaded files directory
- No file type restrictions
- Publicly accessible

## Technology Stack

| Container | Technology | Port |
|-----------|-----------|------|
| Nginx | nginx:latest | 80, 443 |
| React Frontend | React 18.2, React Router 6 | - |
| Node Backend | Node.js 16, Express.js | 3000 |
| MySQL | MySQL 8.0 | 3306 |
| File Storage | Local filesystem | - |

## Security Characteristics

- ⚠️ All containers run in Docker
- ⚠️ Backend has NO input validation
- ⚠️ Database stores plain text passwords
- ⚠️ File upload has NO restrictions
- ⚠️ No rate limiting
- ⚠️ Predictable session tokens
- ⚠️ Environment files exposed

