# W Corp Cyber Range - System Decomposition

## 📐 Architecture & Design Documentation

This folder contains comprehensive system architecture diagrams using the C4 model, data flow diagrams, and message sequence diagrams to fully document the W Corp Cyber Range application.

---

## 📚 Documentation Index

### C4 Model Diagrams

The C4 model provides a hierarchical view of the system architecture, from high-level context down to detailed components.

#### [C4-CONTEXT.md](C4-CONTEXT.md) - Level 1: System Context
**"Who uses the system and what other systems does it interact with?"**

- Shows W Corp Cyber Range in relation to external entities
- Identifies users (trainees, instructors, attackers)
- Maps external systems (browsers, security tools)
- **Use when**: Understanding overall system purpose and boundaries

```
┌─────────────┐
│   Trainee   │────> W Corp Cyber Range <────┤ Security Tools │
└─────────────┘                               └────────────────┘
```

---

#### [C4-CONTAINER.md](C4-CONTAINER.md) - Level 2: Container Diagram
**"What are the major technology components and how do they communicate?"**

- Nginx reverse proxy
- React frontend (/wcorp)
- Landing page (/)
- Node.js/Express backend
- MySQL database
- File storage system
- **Use when**: Understanding technology stack and deployment architecture

```
┌──────┐    ┌───────┐    ┌──────────┐    ┌───────┐
│ User │───>│ Nginx │───>│ React    │───>│ Node  │───>│ MySQL │
└──────┘    └───────┘    │ Frontend │    │Backend│    └───────┘
                         └──────────┘    └───────┘
```

---

#### [C4-COMPONENT.md](C4-COMPONENT.md) - Level 3: Component Diagram
**"What components make up each container and their responsibilities?"**

- Express router and middleware
- Controllers (Auth, User, Admin, Upload, SSRF, Search)
- Services (Token Generator, Database Connection, File Handler)
- Maps vulnerabilities to specific components
- **Use when**: Understanding internal structure and vulnerability locations

```
┌────────────────────────────────────────────┐
│         Node.js Backend                    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐│
│  │  Auth    │  │   User   │  │  Admin   ││
│  │Controller│  │Controller│  │Controller││
│  └──────────┘  └──────────┘  └──────────┘│
│       │             │              │       │
│  ┌────┴─────────────┴──────────────┘      │
│  │      Database Connection                │
│  └─────────────────────────────────────────┘
└────────────────────────────────────────────┘
```

---

### Data Flow Diagrams

Visualize how data moves through the system and where vulnerabilities can be exploited.

#### [DATA-FLOW.md](DATA-FLOW.md) - Complete Data Flow Documentation

**Includes 6 detailed flow diagrams:**

1. **User Authentication Flow**
   - Shows safe vs vulnerable login paths
   - Highlights plain text passwords
   - Token generation and storage
   - **Use when**: Understanding authentication mechanism

2. **IDOR Attack Data Flow**
   - Step-by-step IDOR exploitation
   - Missing authorization checks
   - Data enumeration process
   - **Use when**: Learning/teaching IDOR vulnerabilities

3. **SQL Injection Attack Data Flow**
   - String concatenation vulnerability
   - Query construction process
   - Authentication bypass
   - Data extraction via UNION
   - **Use when**: Understanding SQL injection mechanics

4. **File Upload Attack Data Flow**
   - Missing validation steps
   - Malicious file processing
   - XSS payload delivery
   - Victim compromise
   - **Use when**: Learning unrestricted upload risks

5. **SSRF Attack Data Flow**
   - URL parameter exploitation
   - Internal resource access
   - Cloud metadata theft
   - Network enumeration
   - **Use when**: Understanding SSRF impact

6. **Complete Attack Chain**
   - Multi-stage attack progression
   - Vulnerability chaining
   - Privilege escalation path
   - Full system compromise
   - **Use when**: Understanding real-world attack scenarios

---

### Message Sequence Diagrams

Show step-by-step interactions between system components and actors over time.

#### [SEQUENCE-DIAGRAMS.md](SEQUENCE-DIAGRAMS.md) - Temporal Interaction Documentation

**Includes 6 detailed sequence diagrams:**

1. **User Registration Sequence**
   - Client-side validation
   - Parameter tampering opportunity
   - Plain text password storage
   - Database interaction
   - **Use when**: Understanding registration flow and A02/A03 vulns

2. **Login & Authentication Sequence**
   - Credential verification
   - Predictable token generation
   - Session creation
   - Client-side token storage
   - **Use when**: Understanding authentication and A07 vulns

3. **IDOR Attack Sequence**
   - Token validation
   - Missing authorization check
   - Unauthorized data access
   - Automated enumeration
   - **Use when**: Step-by-step IDOR exploitation

4. **SQL Injection Attack Sequence**
   - Payload crafting
   - String concatenation
   - SQL comment injection
   - Data extraction escalation
   - **Use when**: Understanding SQL injection timeline

5. **File Upload & XSS Attack Sequence**
   - Malicious file creation
   - Missing validation
   - Social engineering
   - Victim XSS execution
   - Session theft
   - **Use when**: Understanding XSS via file upload

6. **SSRF Attack Sequence**
   - Endpoint discovery
   - Internal access attempts
   - Cloud metadata retrieval
   - Network reconnaissance
   - **Use when**: Understanding SSRF exploitation progression

---

## 🎯 How to Use This Documentation

### For Learning

1. **Start with C4-CONTEXT** to understand the big picture
2. **Move to C4-CONTAINER** to see technology choices
3. **Read DATA-FLOW** for specific vulnerability patterns
4. **Study SEQUENCE-DIAGRAMS** for attack execution details

### For Teaching

1. **Use C4 diagrams** in presentations for architecture overview
2. **Use DATA-FLOW** to explain vulnerability mechanics
3. **Use SEQUENCE diagrams** to demonstrate attacks step-by-step
4. **Reference specific vulnerabilities** by component (C4-COMPONENT)

### For Security Analysis

1. **C4-COMPONENT** - Map vulnerabilities to code locations
2. **DATA-FLOW** - Identify data paths and validation gaps
3. **SEQUENCE-DIAGRAMS** - Understand attack surface timing
4. **Cross-reference** with [VULNERABILITY-GUIDE.md](../VULNERABILITY-GUIDE.md)

---

## 🗺️ Diagram Quick Reference

### By Vulnerability Type

| Vulnerability | Best Diagram | File |
|---------------|-------------|------|
| **A01 - IDOR** | IDOR Attack Sequence | [SEQUENCE-DIAGRAMS.md](SEQUENCE-DIAGRAMS.md#3-idor-attack-sequence) |
| **A02 - Crypto Failures** | Authentication Flow | [DATA-FLOW.md](DATA-FLOW.md#1-user-authentication-flow) |
| **A03 - SQL Injection** | SQL Injection Sequence | [SEQUENCE-DIAGRAMS.md](SEQUENCE-DIAGRAMS.md#4-sql-injection-attack-sequence) |
| **A05 - Misconfiguration** | SSRF Data Flow | [DATA-FLOW.md](DATA-FLOW.md#5-ssrf-attack-data-flow) |
| **A07 - Auth Failures** | Login Sequence | [SEQUENCE-DIAGRAMS.md](SEQUENCE-DIAGRAMS.md#2-login--authentication-sequence) |
| **A08 - File Upload** | File Upload Sequence | [SEQUENCE-DIAGRAMS.md](SEQUENCE-DIAGRAMS.md#5-file-upload--xss-attack-sequence) |
| **A10 - SSRF** | SSRF Sequence | [SEQUENCE-DIAGRAMS.md](SEQUENCE-DIAGRAMS.md#6-ssrf-attack-sequence) |

### By Component

| Component | Best Diagram | File |
|-----------|-------------|------|
| **Nginx** | Container Diagram | [C4-CONTAINER.md](C4-CONTAINER.md) |
| **React Frontend** | Container Diagram | [C4-CONTAINER.md](C4-CONTAINER.md) |
| **Express Backend** | Component Diagram | [C4-COMPONENT.md](C4-COMPONENT.md) |
| **Auth Controller** | Component Diagram | [C4-COMPONENT.md](C4-COMPONENT.md) |
| **MySQL Database** | Container Diagram | [C4-CONTAINER.md](C4-CONTAINER.md) |

### By Use Case

| Use Case | Recommended Reading Order |
|----------|--------------------------|
| **Architecture Overview** | C4-CONTEXT → C4-CONTAINER → C4-COMPONENT |
| **Understanding Attacks** | DATA-FLOW (specific attack) → SEQUENCE-DIAGRAMS (same attack) |
| **Teaching OWASP Top 10** | C4-COMPONENT (map vulns) → DATA-FLOW (show exploits) |
| **Security Assessment** | C4-CONTAINER → C4-COMPONENT → DATA-FLOW |
| **Penetration Testing** | SEQUENCE-DIAGRAMS → DATA-FLOW (attack chains) |

---

## 📊 Diagram Statistics

- **C4 Diagrams**: 3 (Context, Container, Component)
- **Data Flow Diagrams**: 6
- **Sequence Diagrams**: 6
- **Total Diagrams**: 15
- **Vulnerabilities Covered**: 14 (8 server-side, 6 client-side)
- **Attack Scenarios**: 20+

---

## 🔍 Diagram Symbols & Conventions

### C4 Diagrams
- **Person** (Blue): Human actors
- **System** (Blue box): Software systems
- **Container** (Blue box): Applications/services
- **Component** (Blue box): Code components
- **Database** (Cylinder): Data stores
- **Red highlights**: Vulnerable components

### Data Flow Diagrams
- **Blue nodes**: Normal operations
- **Red nodes**: Vulnerable operations
- **Dark red nodes**: Critical vulnerabilities
- **Green nodes**: Secure implementations

### Sequence Diagrams
- **Solid lines**: Synchronous calls
- **Dashed lines**: Responses
- **Red notes**: Vulnerabilities
- **Yellow boxes**: Warning/critical steps

---

## 🔗 Related Documentation

- [VULNERABILITY-GUIDE.md](../VULNERABILITY-GUIDE.md) - Detailed vulnerability exploitation
- [SQL-INJECTION-CHEATSHEET.md](../SQL-INJECTION-CHEATSHEET.md) - Quick SQL injection reference
- [UI-ATTACKS-GUIDE.md](../UI-ATTACKS-GUIDE.md) - Client-side attack documentation
- [ATTACK-SUMMARY.md](../ATTACK-SUMMARY.md) - All vulnerabilities quick reference
- [cyber-kill-chain.md](../cyber-kill-chain.md) - Attack progression framework

---

## 💡 Tips for Reading Diagrams

1. **C4 diagrams are hierarchical** - Read top-down from Context → Container → Component
2. **Data flow shows movement** - Follow arrows to understand data paths
3. **Sequence diagrams show time** - Read top-down for chronological order
4. **Red = Vulnerable** - Focus on red-highlighted areas for security issues
5. **Cross-reference** - Use multiple diagram types for complete understanding

---

## 🎓 Educational Use

These diagrams are designed for:

- **Security training courses**
- **University cybersecurity programs**
- **Penetration testing workshops**
- **OWASP Top 10 demonstrations**
- **Secure coding training**
- **Architecture review training**

Feel free to use these diagrams in educational materials!

---

## 🛠️ Viewing Mermaid Diagrams

Mermaid diagrams can be viewed in:

1. **GitHub/GitLab** - Native rendering
2. **VS Code** - Mermaid Preview extension
3. **Mermaid Live Editor** - https://mermaid.live
4. **Markdown viewers** - Most support Mermaid
5. **Documentation sites** - Docsify, MkDocs, etc.

---

## 📝 Version History

- **v1.0** (October 2025) - Initial comprehensive diagram set
  - 3 C4 model diagrams
  - 6 data flow diagrams
  - 6 sequence diagrams
  - Complete vulnerability mapping

---

© 2025 W Corp Cyber Range - Educational Security Training Platform

**Last Updated:** October 6, 2025

