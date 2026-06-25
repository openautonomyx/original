# Publishing Platform - Content Management Module

## 📝 Web Content Management Service

Standalone module for creating, editing, and publishing content across all formats.

---

## 🏗️ Project Structure

```
publishing-platform-content/
├── src/
│   ├── api/
│   │   ├── routes.ts           # Express routes
│   │   ├── middleware.ts       # Auth, validation
│   │   └── handlers/
│   │       ├── contentHandler.ts
│   │       ├── publishHandler.ts
│   │       └── versionHandler.ts
│   ├── services/
│   │   ├── contentService.ts   # Business logic
│   │   ├── publishService.ts   # Publishing logic
│   │   └── versionService.ts   # Version control
│   ├── models/
│   │   ├── content.ts          # TypeORM models
│   │   ├── version.ts
│   │   └── publication.ts
│   ├── events/
│   │   └── contentEvents.ts    # Event emissions
│   ├── utils/
│   │   ├── validators.ts
│   │   └── formatters.ts
│   └── index.ts                # App entry
├── database/
│   └── migrations/
│       └── 001_create_content_tables.sql
├── tests/
│   ├── content.test.ts
│   ├── publish.test.ts
│   └── version.test.ts
├── Dockerfile
├── k8s-deployment.yaml
├── docker-compose.yml
├── package.json
├── tsconfig.json
├── .env.example
└── README.md
```

---

## 🔧 API Endpoints

```
POST   /api/v1/content           # Create content
GET    /api/v1/content/:id       # Get content
PUT    /api/v1/content/:id       # Update content
DELETE /api/v1/content/:id       # Delete content
GET    /api/v1/content           # List content (paginated)

POST   /api/v1/content/:id/publish    # Publish content
GET    /api/v1/content/:id/status     # Get publish status
POST   /api/v1/content/:id/unpublish  # Unpublish

GET    /api/v1/content/:id/versions   # Get versions
GET    /api/v1/content/:id/version/:v # Get specific version
POST   /api/v1/content/:id/restore    # Restore version

POST   /api/v1/content/:id/categories # Assign Gartner category
GET    /api/v1/content/category/:cat  # Get by category
```

---

## 📦 TypeScript Models

```typescript
// src/models/content.ts
import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('content')
export class Content {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  title: string;

  @Column('text')
  description: string;

  @Column('text')
  body: string;

  @Column({ type: 'enum', enum: ['blog', 'whitepaper', 'case-study', 'guide', 'tutorial'] })
  type: ContentType;

  @Column('simple-array')
  tags: string[];

  @Column('json')
  metadata: {
    seo?: { title: string; description: string; keywords: string[] };
    featured?: boolean;
    readingTime?: number;
  };

  @Column('uuid', { nullable: true })
  gartnerCategoryId: string;

  @Column({ type: 'enum', enum: ['draft', 'published', 'archived'], default: 'draft' })
  status: ContentStatus;

  @Column('uuid')
  createdBy: string;

  @Column('uuid', { nullable: true })
  updatedBy: string;

  @Column('uuid', { nullable: true })
  publishedBy: string;

  @Column({ nullable: true })
  publishedAt: Date;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

export type ContentType = 'blog' | 'whitepaper' | 'case-study' | 'guide' | 'tutorial';
export type ContentStatus = 'draft' | 'published' | 'archived';
```

---

## 🎯 Service Layer

```typescript
// src/services/contentService.ts
import { Repository } from 'typeorm';
import { Content } from '../models/content';
import { EventBus } from '@publishing-platform/core';

export class ContentService {
  constructor(
    private contentRepo: Repository<Content>,
    private eventBus: EventBus
  ) {}

  async createContent(data: CreateContentDTO, userId: string): Promise<Content> {
    const content = this.contentRepo.create({
      ...data,
      createdBy: userId,
      status: 'draft'
    });

    const saved = await this.contentRepo.save(content);

    // Emit event
    this.eventBus.publish({
      type: 'content.created',
      source: 'content-management',
      data: saved
    });

    return saved;
  }

  async updateContent(id: string, data: UpdateContentDTO, userId: string): Promise<Content> {
    const content = await this.contentRepo.findOneOrFail(id);

    // Create version before update
    await this.createVersion(content);

    Object.assign(content, data);
    content.updatedBy = userId;

    const updated = await this.contentRepo.save(content);

    this.eventBus.publish({
      type: 'content.updated',
      source: 'content-management',
      data: updated
    });

    return updated;
  }

  async publishContent(id: string, userId: string): Promise<Content> {
    const content = await this.contentRepo.findOneOrFail(id);
    
    content.status = 'published';
    content.publishedAt = new Date();
    content.publishedBy = userId;

    const published = await this.contentRepo.save(content);

    this.eventBus.publish({
      type: 'content.published',
      source: 'content-management',
      data: published
    });

    return published;
  }

  async getContentByCategory(categoryId: string): Promise<Content[]> {
    return this.contentRepo.find({
      where: { gartnerCategoryId: categoryId, status: 'published' }
    });
  }

  async listContent(page: number = 1, limit: number = 20): Promise<{ data: Content[]; total: number }> {
    const [data, total] = await this.contentRepo.findAndCount({
      where: { status: 'published' },
      skip: (page - 1) * limit,
      take: limit,
      order: { publishedAt: 'DESC' }
    });

    return { data, total };
  }

  private async createVersion(content: Content): Promise<void> {
    // Save current state as version
    const version = {
      contentId: content.id,
      version: content.version || 1,
      data: JSON.stringify(content),
      createdAt: new Date()
    };

    // Save to versions table
    // await this.versionRepo.save(version);
  }
}
```

---

## 🔌 API Routes

```typescript
// src/api/routes.ts
import express from 'express';
import { authenticateToken, authorize } from './middleware';
import { ContentService } from '../services/contentService';

export function setupContentRoutes(router: express.Router, contentService: ContentService) {
  // Create content
  router.post('/content', authenticateToken, async (req, res) => {
    try {
      const content = await contentService.createContent(req.body, req.user.id);
      res.status(201).json(content);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  });

  // Get content
  router.get('/content/:id', async (req, res) => {
    try {
      const content = await contentService.getContent(req.params.id);
      res.json(content);
    } catch (error) {
      res.status(404).json({ error: 'Content not found' });
    }
  });

  // Update content
  router.put('/content/:id', authenticateToken, authorize('creator'), async (req, res) => {
    try {
      const content = await contentService.updateContent(req.params.id, req.body, req.user.id);
      res.json(content);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  });

  // Publish content
  router.post('/content/:id/publish', authenticateToken, authorize('creator'), async (req, res) => {
    try {
      const content = await contentService.publishContent(req.params.id, req.user.id);
      res.json(content);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  });

  // List content
  router.get('/content', async (req, res) => {
    try {
      const page = parseInt(req.query.page as string) || 1;
      const limit = parseInt(req.query.limit as string) || 20;
      const result = await contentService.listContent(page, limit);
      res.json(result);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  });

  // Get by category
  router.get('/category/:categoryId/content', async (req, res) => {
    try {
      const content = await contentService.getContentByCategory(req.params.categoryId);
      res.json(content);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  });

  return router;
}
```

---

## 🐳 Dockerfile

```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY dist ./dist
COPY tsconfig.json ./

EXPOSE 3001

CMD ["node", "dist/index.js"]
```

---

## ☸️ K3s Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: content-management
  namespace: publishing-platform
spec:
  replicas: 2
  selector:
    matchLabels:
      app: content-management
  template:
    metadata:
      labels:
        app: content-management
    spec:
      containers:
      - name: content-management
        image: ghcr.io/openautonomyx/content-management:latest
        ports:
        - containerPort: 3001
        env:
        - name: NODE_ENV
          value: production
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: url
        - name: EVENT_BUS_URL
          value: "http://event-bus:3001"
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: jwt-secret
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3001
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 3001
          initialDelaySeconds: 5
          periodSeconds: 5

---
apiVersion: v1
kind: Service
metadata:
  name: content-management
  namespace: publishing-platform
spec:
  selector:
    app: content-management
  ports:
  - protocol: TCP
    port: 80
    targetPort: 3001
  type: ClusterIP

---
apiVersion: autoscaling.k8s.io/v2
kind: HorizontalPodAutoscaler
metadata:
  name: content-management-hpa
  namespace: publishing-platform
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: content-management
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

---

## 📦 package.json

```json
{
  "name": "@publishing-platform/content-management",
  "version": "1.0.0",
  "description": "Content Management Module for Publishing Platform",
  "main": "dist/index.js",
  "scripts": {
    "build": "tsc",
    "start": "node dist/index.js",
    "dev": "ts-node src/index.ts",
    "test": "jest",
    "migrate": "typeorm migration:run"
  },
  "dependencies": {
    "@publishing-platform/core": "^1.0.0",
    "express": "^4.18.0",
    "typeorm": "^0.3.0",
    "pg": "^8.11.0",
    "uuid": "^9.0.0"
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

---

## 🚀 Setup & Run

```bash
# Install dependencies
npm install

# Build
npm run build

# Run locally
npm run dev

# Run tests
npm test

# Database migrations
npm run migrate

# Docker
docker build -t content-management:latest .
docker run -p 3001:3001 content-management:latest

# Deploy to K3s
kubectl apply -f k8s-deployment.yaml
```

---

## ✅ Ready to Build?

This is the complete Content Management module blueprint. 

Ready to:
1. Create the @publishing-platform/core library first?
2. Or create API Gateway?
3. Or start building this module?

🎯
