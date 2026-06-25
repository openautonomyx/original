# Architecture

Publishing Platform is a semantic-native publishing system built as a TypeScript monorepo.

## Core Layers

```text
apps/web                 Astro SSR app and API routes
packages/schema          Schema.org / JSON-LD domain model
packages/db              SurrealDB client and repositories
packages/core            Shared domain logic
packages/auth            Authentication and authorization foundation
```

## Runtime

The web app runs on Astro SSR with the Node adapter in standalone mode. This aligns the app with Docker, Kubernetes, and traditional Node-based hosting platforms.

## Data Model

The platform stores publishing records as Schema.org-compatible CreativeWork documents.

Each stored content record uses this shape:

```ts
{
  tenant?: string;
  slug?: string;
  status: 'draft' | 'review' | 'published' | 'archived';
  schema: CreativeWork;
  createdAt: string;
  updatedAt: string;
}
```

## Database

SurrealDB is used as the graph/document database. This is a good fit for publishing because content can be modeled as documents while also supporting semantic relationships between people, organizations, places, works, citations, topics, and media.

## Deployment

The app supports:

- local pnpm development
- Docker builds
- Docker Compose
- GitHub Actions CI
- GitHub Container Registry publishing
- Kubernetes manifests

## Request Flow

```text
Browser / API Client
  -> Astro SSR app
  -> Astro API routes
  -> @publishing-platform/db
  -> SurrealDB
```

## API Surface

Current API routes:

- `GET /api/health`
- `GET /api/creative-works`
- `POST /api/creative-works`

More endpoints should be added for single-record reads, updates, deletes, publishing workflow transitions, auth, media, and search.
