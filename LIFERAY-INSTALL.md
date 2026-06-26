# Liferay DXP Installation Guide

## Option 1: Docker (Fastest - Recommended)

### Step 1: Start Liferay with Docker

```bash
docker run -d \
  --name liferay \
  -p 8080:8080 \
  -p 11311:11311 \
  -e LIFERAY_WORKSPACE_ENABLED="true" \
  liferay/dxp:latest
```

**Wait 3-5 minutes** for Liferay to start (it's downloading dependencies).

### Step 2: Check if Running

```bash
# View logs
docker logs -f liferay

# Once you see: "Server startup complete"
# It's ready!
```

### Step 3: Access Liferay

Open browser:
```
http://localhost:8080
```

**Default Login:**
- Email: `test@liferay.com`
- Password: `test`

---

## Option 2: Docker Compose (With Database)

### Create docker-compose.yml

```yaml
version: '3.9'

services:
  postgres:
    image: postgres:15-alpine
    container_name: liferay-postgres
    environment:
      POSTGRES_DB: liferay
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - liferay-network

  liferay:
    image: liferay/dxp:latest
    container_name: liferay
    ports:
      - "8080:8080"
      - "11311:11311"
    environment:
      LIFERAY_JDBC_ONE_URL: "jdbc:postgresql://postgres:5432/liferay"
      LIFERAY_JDBC_ONE_DRIVER_CLASS_NAME: "org.postgresql.Driver"
      LIFERAY_JDBC_ONE_USERNAME: "postgres"
      LIFERAY_JDBC_ONE_PASSWORD: "postgres"
      LIFERAY_SETUP_WIZARD_ENABLED: "false"
    depends_on:
      - postgres
    volumes:
      - liferay_data:/opt/liferay/data
    networks:
      - liferay-network
    restart: unless-stopped

volumes:
  postgres_data:
  liferay_data:

networks:
  liferay-network:
    driver: bridge
```

### Run

```bash
docker-compose up -d

# Wait for startup
docker-compose logs -f liferay

# Access: http://localhost:8080
```

---

## Option 3: Direct Download (Advanced)

### Step 1: Download

```bash
# Download Liferay DXP 7.4
wget https://releases.liferay.com/portal/7.4.13.25/liferay-dxp-tomcat-7.4.13.25-20240620.tar.gz

# Extract
tar -xzf liferay-dxp-tomcat-7.4.13.25-20240620.tar.gz

# Navigate
cd liferay-dxp-7.4.13.25
```

### Step 2: Start

```bash
# On Linux/Mac
./tomcat/bin/startup.sh

# On Windows
./tomcat/bin/startup.bat

# Wait ~3 minutes for startup
```

### Step 3: Access

```
http://localhost:8080
```

---

## Option 4: Liferay Cloud (Production)

```bash
# Sign up at: https://console.liferay.cloud/

# Create new project
# Select: DXP 7.4

# Deploy:
# 1. Create workspace
# 2. Clone repo
# 3. Deploy to staging/production
```

---

## Post-Installation Setup

### Step 1: Initial Configuration

1. Go to: `http://localhost:8080`
2. Complete setup wizard (or skip if WIZARD disabled)
3. Login with: `test@liferay.com / test`

### Step 2: Create First Site

**In Liferay Control Panel:**

```
Sites → New Site
├─ Name: "OpenAutonomyX Publishing"
├─ Template: Blank
└─ Create
```

### Step 3: Add Pages

**In Site Settings:**

```
Pages → Add Page
├─ Create the following pages:
├─ /dashboard
├─ /blog
├─ /create-content
├─ /formats
├─ /integrations
├─ /analytics
└─ /admin
```

### Step 4: Create Experiences

**In Site → Experiences:**

```
New Experience
├─ Name: "Creator Experience"
├─ Segments: Creators
└─ Create

New Experience
├─ Name: "Reader Experience"
├─ Segments: Readers
└─ Create

New Experience
├─ Name: "Admin Experience"
├─ Segments: Administrators
└─ Create
```

---

## Install Liferay Blade CLI (For Development)

```bash
# Install Blade CLI
# On Mac (Homebrew)
brew install liferay/blade/blade

# On Linux
curl https://releases.liferay.com/tools/blade-cli/latest/blade-latest.jar -o blade.jar
java -jar blade.jar install

# Verify
blade version
```

---

## Create Your First Portlet

### Using Blade

```bash
# Create workspace
blade init -t gradle my-liferay-workspace

cd my-liferay-workspace

# Create portlet
blade create -t mvc-portlet \
  -p com.liferay.publishing \
  content-creator-portlet

# Build
cd modules/content-creator-portlet
./gradlew build

# Deploy (copy JAR to Liferay deploy folder)
cp build/libs/content-creator-portlet.jar $LIFERAY_HOME/deploy/
```

---

## Verify Installation

### Check Liferay is Running

```bash
# Test health endpoint
curl -X GET http://localhost:8080/api/liferay/v1/health-check

# Should return 200 OK
```

### Check Docker Container

```bash
# View running containers
docker ps | grep liferay

# View logs
docker logs -f liferay

# Stop Liferay
docker stop liferay

# Start Liferay
docker start liferay
```

---

## Configuration: Connect to Our Backend

### Step 1: Create portal-ext.properties

In Liferay home directory:

```bash
# Create file
touch $LIFERAY_HOME/portal-ext.properties

# Add configuration
cat >> $LIFERAY_HOME/portal-ext.properties << EOF

# OpenAutonomyX Backend Configuration
openautonomyx.api.gateway.url=http://localhost:3000
openautonomyx.blog.service.url=http://localhost:3009
openautonomyx.formats.service.url=http://localhost:3011
openautonomyx.integrations.service.url=http://localhost:3010
openautonomyx.analytics.service.url=http://localhost:3005
openautonomyx.content.service.url=http://localhost:3002

# API Authentication
openautonomyx.api.key=your-api-key-here
openautonomyx.api.secret=your-api-secret-here

# CORS Configuration
cors.allowed.origins=localhost:3000,localhost:5173,localhost:8080

EOF
```

### Step 2: Restart Liferay

```bash
# Docker
docker restart liferay

# Direct installation
./tomcat/bin/shutdown.sh
./tomcat/bin/startup.sh
```

---

## Troubleshooting

### Liferay Won't Start

```bash
# Check logs
docker logs liferay

# If disk space issue:
docker system prune -a

# If port taken:
lsof -i :8080
kill -9 <PID>

# Restart
docker restart liferay
```

### Can't Access http://localhost:8080

```bash
# Check if running
docker ps | grep liferay

# Check logs
docker logs liferay

# Wait 5+ minutes - it takes time to start
```

### Database Connection Error

```bash
# Ensure PostgreSQL is running
docker ps | grep postgres

# Check env vars match
docker inspect liferay | grep LIFERAY_JDBC
```

### Port 8080 Already in Use

```bash
# Use different port
docker run -d \
  --name liferay \
  -p 9090:8080 \
  liferay/dxp:latest

# Access: http://localhost:9090
```

---

## Admin Panel Access

### Login

```
Email: test@liferay.com
Password: test
```

### Go to Control Panel

```
Profile (top right) → Control Panel
```

### Key Areas

```
Control Panel
├─ Sites (manage sites)
├─ Users (manage users)
├─ Pages (manage pages)
├─ Roles & Permissions
├─ Apps (installed portlets)
├─ Server Administration
└─ System Settings
```

---

## Full Stack Running

```bash
# Terminal 1: Liferay
docker run -d -p 8080:8080 liferay/dxp:latest

# Terminal 2: OpenAutonomyX Backend
cd /Users/chinmaypanda/CustomApps
docker-compose up -d

# Terminal 3: Our Frontend (optional - we're using Liferay now)
cd frontend
npm run dev

# Access:
# Liferay Portal: http://localhost:8080
# Backend APIs: http://localhost:3000
# (Frontend: http://localhost:5173 - optional)
```

---

## Next Steps

1. ✅ Liferay installed & running
2. ⬜ Create site "OpenAutonomyX Publishing"
3. ⬜ Add pages (dashboard, blog, create, formats, integrations)
4. ⬜ Create experiences (Creator, Reader, Admin)
5. ⬜ Build custom portlets:
   - Content Creator Portlet
   - Format Converter Portlet
   - Integrations Manager Portlet
6. ⬜ Connect to backend APIs
7. ⬜ Deploy!

---

## Useful Commands

```bash
# View Liferay logs
docker logs -f liferay

# Enter Liferay container
docker exec -it liferay /bin/bash

# Stop Liferay
docker stop liferay

# Remove Liferay
docker rm liferay

# Pull latest image
docker pull liferay/dxp:latest

# Check disk usage
docker system df

# Clean up
docker system prune -a
```

---

## Resources

- Docs: https://learn.liferay.com/
- Community: https://community.liferay.com/
- GitHub: https://github.com/liferay/liferay-portal
- Issues: https://issues.liferay.com/

---

**Liferay DXP Ready!** 🚀
