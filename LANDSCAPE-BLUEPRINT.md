# Publishing Platform - Landscape Blueprint

## 📂 Complete Project Structure

```
publishing-platform/
├── docker-compose.yml          # Orchestration
├── LANDSCAPE-BLUEPRINT.md      # This file
├── DOCKER-COMPOSE-GUIDE.md     # Usage guide
├── README.md                   # Main docs
│
├── services/                   # All microservices
│   ├── api-gateway/
│   │   ├── src/
│   │   │   ├── index.ts
│   │   │   ├── middleware.ts
│   │   │   └── routes.ts
│   │   ├── Dockerfile
│   │   └── package.json
│   │
│   ├── event-bus/
│   │   ├── src/
│   │   │   ├── index.ts
│   │   │   ├── broker.ts
│   │   │   └── store.ts
│   │   ├── Dockerfile
│   │   └── package.json
│   │
│   └── [content-management, skills, tools, analytics, optimization, design, features]/
│       ├── src/
│       │   ├── index.ts        # App entry
│       │   ├── api/            # Routes
│       │   ├── services/       # Business logic
│       │   ├── models/         # Data models
│       │   ├── events/         # Event handlers
│       │   └── utils/          # Utilities
│       ├── database/
│       │   └── migrations/     # DB migrations
│       ├── tests/
│       │   └── *.test.ts
│       ├── Dockerfile
│       ├── docker-compose.yml  # Local dev
│       ├── package.json
│       └── tsconfig.json
│
├── database/                   # Database setup
│   ├── init.sql               # Initialization
│   ├── schema.sql             # Full schema
│   └── migrations/
│       ├── 001_create_users.sql
│       ├── 002_create_content.sql
│       ├── 003_create_gartner.sql
│       └── ...
│
├── config/                     # Configuration
│   ├── local/
│   │   └── .env.local
│   ├── development/
│   │   └── .env.development
│   ├── production/
│   │   └── .env.production
│   └── kubernetes/
│       ├── configmap.yaml
│       └── secrets.yaml
│
├── scripts/                    # Automation
│   ├── db/
│   │   ├── migrate.sh
│   │   ├── seed.sh
│   │   └── backup.sh
│   ├── deployment/
│   │   ├── build.sh
│   │   ├── push.sh
│   │   └── deploy.sh
│   └── monitoring/
│       └── health-check.sh
│
├── docs/                       # Documentation
│   ├── architecture/
│   │   ├── OVERVIEW.md
│   │   ├── DATABASE.md
│   │   └── SERVICES.md
│   ├── guides/
│   │   ├── SETUP.md
│   │   ├── DEPLOYMENT.md
│   │   └── TESTING.md
│   └── api/
│       ├── ENDPOINTS.md
│       ├── AUTHENTICATION.md
│       └── ERRORS.md
│
├── k8s/                        # Kubernetes
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── secrets.yaml
│   ├── services/
│   │   ├── api-gateway.yaml
│   │   ├── content-management.yaml
│   │   └── ...
│   ├── ingress.yaml
│   └── hpa.yaml
│
├── monitoring/                 # Observability
│   ├── prometheus.yml
│   ├── grafana-dashboard.json
│   └── logging.yaml
│
├── tests/                      # E2E tests
│   ├── integration/
│   │   └── workflow.test.ts
│   └── load/
│       └── loadtest.ts
│
├── .github/                    # CI/CD
│   └── workflows/
│       ├── build.yml
│       ├── test.yml
│       └── deploy.yml
│
├── .dockerignore
├── .gitignore
├── .env.example
└── Makefile                    # Quick commands
```

---

## 🛠️ Service Scaffold Template

Each service follows this structure:

### package.json
```json
{
  "name": "@publishing-platform/[service-name]",
  "version": "1.0.0",
  "description": "[Service description]",
  "main": "dist/index.js",
  "scripts": {
    "build": "tsc",
    "start": "node dist/index.js",
    "dev": "ts-node src/index.ts",
    "test": "jest",
    "migrate": "node scripts/migrate.js"
  },
  "dependencies": {
    "@publishing-platform/core": "^1.0.0",
    "express": "^4.18.0",
    "typeorm": "^0.3.0",
    "pg": "^8.11.0"
  },
  "devDependencies": {
    "@types/express": "^4.17.0",
    "@types/node": "^20.0.0",
    "typescript": "^5.2.0",
    "jest": "^29.7.0",
    "ts-jest": "^29.1.0"
  }
}
```

### Dockerfile
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY dist ./dist
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"
CMD ["node", "dist/index.js"]
```

### src/index.ts (Skeleton)
```typescript
import express from 'express';
import { setupRoutes } from './api/routes';

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'service-name' });
});

// Routes
setupRoutes(app);

// Error handling
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error(err);
  res.status(500).json({ error: 'Internal Server Error' });
});

app.listen(PORT, () => {
  console.log(`Service running on port ${PORT}`);
});
```

---

## 🗄️ Database Schema

### init.sql
```sql
-- Create extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255),
  roles TEXT[] DEFAULT ARRAY['guest'],
  permissions TEXT[] DEFAULT ARRAY[],
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Gartner Categories
CREATE TABLE IF NOT EXISTS gartner_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  market_name VARCHAR(255),
  quadrant VARCHAR(50),
  industry VARCHAR(255),
  vendor VARCHAR(255),
  score FLOAT,
  capabilities TEXT[],
  tags TEXT[],
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Content
CREATE TABLE IF NOT EXISTS content (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title VARCHAR(255),
  description TEXT,
  body TEXT,
  type VARCHAR(50),
  status VARCHAR(50) DEFAULT 'draft',
  gartner_category_id UUID REFERENCES gartner_categories(id),
  created_by UUID REFERENCES users(id),
  published_by UUID REFERENCES users(id),
  published_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Skills
CREATE TABLE IF NOT EXISTS skills (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(255),
  category_id UUID REFERENCES gartner_categories(id),
  level VARCHAR(50),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_content_status ON content(status);
CREATE INDEX idx_content_category ON content(gartner_category_id);
CREATE INDEX idx_skills_category ON skills(category_id);
```

---

## 🚀 Quick Setup

```bash
# 1. Create landscape
bash LANDSCAPE-SETUP.sh

# 2. Copy core library
npm install @publishing-platform/core

# 3. Build all services
docker-compose build

# 4. Run database migrations
docker-compose run postgres psql -U pp_admin -d publishing_platform < database/init.sql

# 5. Start platform
docker-compose up -d

# 6. Verify
docker-compose ps
curl http://localhost:3000/health
```

---

## 📊 Service Matrix

| Service | Port | Dependencies | Database | Cache | Storage |
|---------|------|--------------|----------|-------|---------|
| API Gateway | 3000 | - | - | Redis | - |
| Event Bus | 3001 | Redis | - | Redis | - |
| Content | 3002 | Event Bus | ✓ | Redis | MinIO |
| Skills | 3003 | Event Bus | ✓ | - | - |
| Tools | 3004 | Event Bus | ✓ | - | MinIO |
| Analytics | 3005 | Event Bus | ✓ | Elasticsearch | - |
| Optimization | 3006 | Event Bus, Ollama | ✓ | Redis | - |
| Design | 3007 | Event Bus | ✓ | - | MinIO |
| Features | 3008 | Event Bus | ✓ | Redis | - |

---

## 🔄 Development Workflow

```bash
# Start everything
docker-compose up -d

# Watch logs
docker-compose logs -f

# Code in services/[name]/src/

# Rebuild one service
docker-compose build content-management

# Restart one service
docker-compose restart content-management

# Run migrations
docker-compose exec postgres psql -U pp_admin -d publishing_platform < database/migrations/001_*.sql

# Stop all
docker-compose down
```

---

## ✅ Landscape Complete

All scaffolding is in place. Ready to build each service:

1. ✅ Directory structure created
2. ✅ Dockerfile template ready
3. ✅ package.json template ready
4. ✅ Database schema defined
5. ✅ Service skeleton ready
6. ✅ Docker-compose configured

**Next:** Build individual services 🏗️
