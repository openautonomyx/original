# Build All 4 Modules - Implementation Guide

## 📦 1. @publishing-platform/core

**Status:** ✅ Specification ready (core-library-package.ts)

### Files to Create:
```
src/
├── types/index.ts          (All shared interfaces)
├── auth/index.ts           (AuthService class)
├── events/index.ts         (EventBus class)
├── utils/index.ts          (Validation, Formatting)
├── middleware/index.ts     (Middleware factories)
└── index.ts                (Main exports)
```

### Build & Publish:
```bash
mkdir publishing-platform-core && cd publishing-platform-core
npm init -y
npm install jsonwebtoken uuid typescript
npm run build
npm publish --access public
```

### Usage by other modules:
```typescript
import { 
  AuthService, 
  EventBus, 
  ValidationUtils,
  User, 
  Event, 
  JWTPayload 
} from '@publishing-platform/core';
```

---

## 🌐 2. API Gateway

**Status:** ✅ Ready to build

### Key Features:
- Route to all modules
- JWT authentication middleware
- Rate limiting
- Request logging
- Error handling

### Files:
```
src/
├── routes.ts              (Route setup)
├── middleware.ts          (Auth, rate limit, logging)
├── config.ts              (Configuration)
└── index.ts               (Express app)
```

### Implementation:
```typescript
import express from 'express';
import { AuthService, EventBus } from '@publishing-platform/core';

const app = express();
const auth = new AuthService(process.env.JWT_SECRET!);
const eventBus = new EventBus();

// Middleware
app.use(express.json());
app.use(authMiddleware(auth));
app.use(rateLimitMiddleware());

// Routes
app.use('/api/v1/content', contentModuleRouter);
app.use('/api/v1/analytics', analyticsModuleRouter);
app.use('/api/v1/design', designModuleRouter);
app.use('/api/v1/skills', skillsModuleRouter);
app.use('/api/v1/optimization', optimizationModuleRouter);
app.use('/api/v1/features', featureStoreRouter);

app.listen(3000, () => console.log('API Gateway running on :3000'));
```

### Deployment:
```bash
docker build -t api-gateway:latest .
kubectl apply -f k8s-deployment.yaml
```

---

## 🔌 3. Event Bus Service

**Status:** ✅ Ready to build

### Key Features:
- Pub/Sub message broker
- Event persistence (optional Redis)
- Event replay/history
- Service-to-service communication

### Files:
```
src/
├── broker.ts              (Message broker)
├── store.ts               (Event storage)
├── channels.ts            (Channel management)
└── index.ts               (Express app)
```

### Implementation:
```typescript
import express from 'express';
import { EventBus, Event } from '@publishing-platform/core';

const app = express();
const eventBus = new EventBus();

// Health check
app.get('/health', (req, res) => res.json({ status: 'ok' }));

// Publish event
app.post('/events', express.json(), async (req, res) => {
  try {
    await eventBus.publish(req.body);
    res.json({ success: true });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Subscribe to events
app.post('/subscribe', express.json(), async (req, res) => {
  const { eventType, webhookUrl } = req.body;
  eventBus.subscribe(eventType, async (event) => {
    fetch(webhookUrl, { method: 'POST', body: JSON.stringify(event) });
  });
  res.json({ success: true });
});

// Event history
app.get('/events/:type', (req, res) => {
  const events = eventBus.getHistory(req.params.type as any);
  res.json(events);
});

app.listen(3001, () => console.log('Event Bus running on :3001'));
```

---

## 📝 4. Content Management Module

**Status:** ✅ Specification complete (content-management-module.md)

### Key Features:
- CRUD operations
- Version control
- Publishing workflow
- Gartner category tagging
- Event emission

### Files:
```
src/
├── api/routes.ts          (Express routes)
├── services/
│   ├── contentService.ts  (Business logic)
│   ├── publishService.ts  (Publish workflow)
│   └── versionService.ts  (Version control)
├── models/content.ts      (Data models)
├── events/                (Event handlers)
└── index.ts               (App entry)
```

### Implementation:
```typescript
import express from 'express';
import { getRepository } from 'typeorm';
import { AuthService, EventBus } from '@publishing-platform/core';
import { Content } from './models/content';
import { ContentService } from './services/contentService';

const app = express();
const auth = new AuthService(process.env.JWT_SECRET!);
const eventBus = new EventBus();
const contentService = new ContentService(
  getRepository(Content),
  eventBus
);

// Routes
app.post('/content', async (req, res) => {
  const token = auth.verifyToken(req.headers.authorization!);
  const content = await contentService.createContent(req.body, token.userId);
  res.status(201).json(content);
});

app.get('/content/:id', async (req, res) => {
  const content = await contentService.getContent(req.params.id);
  res.json(content);
});

app.listen(3002, () => console.log('Content Management running on :3002'));
```

---

## 🚀 Build Order

### Phase 1: Foundation (2 hours)
1. Create @publishing-platform/core
   - Copy types from core-library-package.ts
   - Build and publish to npm
2. Create Event Bus service
   - Standalone Node.js service
   - Test with curl/Postman

### Phase 2: Gateway (1 hour)
3. Create API Gateway
   - Routes requests to modules
   - Auth middleware
   - Error handling

### Phase 3: Modules (2 hours)
4. Create Content Management
   - Depends on @publishing-platform/core
   - Uses Event Bus
   - Full CRUD API

---

## 📋 Deployment

### Local Development
```bash
# Terminal 1: Event Bus
cd event-bus && npm start

# Terminal 2: API Gateway
cd api-gateway && npm start

# Terminal 3: Content Management
cd content-management && npm start

# Access: http://localhost:3000
```

### Docker
```bash
# Build all
docker build -t api-gateway:latest ./api-gateway
docker build -t content-management:latest ./content-management
docker build -t event-bus:latest ./event-bus

# Docker Compose
docker-compose up -d
```

### Kubernetes (K3s)
```bash
# Deploy all modules
kubectl apply -f api-gateway/k8s-deployment.yaml
kubectl apply -f event-bus/k8s-deployment.yaml
kubectl apply -f content-management/k8s-deployment.yaml

# Check status
kubectl get pods -n publishing-platform
kubectl get svc -n publishing-platform
```

---

## 🔌 API Flow

```
Client Request
    ↓
API Gateway (port 3000)
    ├─ Authenticate (JWT)
    ├─ Route to module
    └─ Log request
    ↓
Content Management (port 3002)
    ├─ Validate input
    ├─ Query database
    ├─ Emit event
    └─ Response
    ↓
Event Bus (port 3001)
    ├─ Store event
    ├─ Notify subscribers
    └─ Update analytics, optimization, etc.
```

---

## ✅ Checklist

- [ ] Create @publishing-platform/core
- [ ] Publish core to npm
- [ ] Create Event Bus service
- [ ] Test Event Bus locally
- [ ] Create API Gateway
- [ ] Wire up routes
- [ ] Create Content Management module
- [ ] Test all 4 services locally
- [ ] Deploy to K3s
- [ ] Test E2E workflow

---

## 🎯 Next Steps

1. Start with @publishing-platform/core (fastest)
2. Test with Event Bus
3. Add API Gateway routing
4. Implement Content Management
5. Deploy all to K3s

Ready to code? 🚀
