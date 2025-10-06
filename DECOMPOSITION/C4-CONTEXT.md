# C4 Model - Context Diagram

## System Context Level

This diagram shows the W Corp Cyber Range system and how it interacts with users and external systems.

[C4 Context](./static/C4%20context.png)

```mermaid
C4Context
    title System Context - W Corp Cyber Range

    Person(trainee, "Security Trainee", "Student learning web security vulnerabilities")
    Person(instructor, "Instructor", "Security professional teaching exploitation techniques")
    Person(attacker, "Simulated Attacker", "User performing penetration testing")
    
    System(wcorp, "W Corp Cyber Range", "Educational platform for learning web application security vulnerabilities (OWASP Top 10)")
    
    System_Ext(browser, "Web Browser", "Chrome, Firefox, Safari")
    System_Ext(tools, "Security Tools", "curl, Burp Suite, sqlmap, browser DevTools")
    
    Rel(trainee, wcorp, "Learns vulnerabilities using", "HTTPS")
    Rel(instructor, wcorp, "Demonstrates attacks using", "HTTPS")
    Rel(attacker, wcorp, "Performs penetration testing on", "HTTPS")
    
    Rel(trainee, browser, "Uses")
    Rel(attacker, tools, "Uses")
    
    Rel(browser, wcorp, "Sends HTTP requests to", "HTTPS")
    Rel(tools, wcorp, "Sends API requests to", "HTTPS")
    
    UpdateRelStyle(trainee, wcorp, $textColor="blue", $lineColor="blue")
    UpdateRelStyle(attacker, wcorp, $textColor="red", $lineColor="red")
```

## Key Interactions

- **Trainees** access the platform to learn about security vulnerabilities in a safe environment
- **Instructors** use it to demonstrate exploitation techniques
- **Simulated Attackers** practice penetration testing skills
- **Security Tools** are used to exploit intentional vulnerabilities
- All interactions happen over **HTTPS** to the deployed instance

## External Dependencies

- Web browsers for UI interaction
- Command-line tools (curl) for API testing
- Security tools (Burp Suite, sqlmap) for advanced exploitation
- Browser DevTools for client-side attacks

