# SurrealDB

## Overview

Publishing Platform uses SurrealDB as its primary database.

SurrealDB provides:

- document storage
- graph relationships
- live queries
- flexible schemas
- SQL-like querying
- semantic relationship modeling

This is useful for semantic publishing systems where people, organizations, works, places, citations, and media are interconnected.

## Local Development

Run SurrealDB locally:

```bash
surreal start --log trace --user root --pass root memory
```

Or with Docker:

```bash
docker run --rm -p 8000:8000 surrealdb/surrealdb:latest start --user root --pass root memory
```

## Environment Variables

```env
SURREALDB_URL=http://127.0.0.1:8000/rpc
SURREALDB_NAMESPACE=publishing_platform
SURREALDB_DATABASE=main
SURREALDB_USERNAME=root
SURREALDB_PASSWORD=root
```

## Client Usage

```ts
import { createSurrealClient } from '@publishing-platform/db';

const db = await createSurrealClient();
```

## CreativeWork Repository

The CreativeWork repository supports:

- create
- read
- update
- delete
- tenant-aware filtering
- publishing states

## Future Extensions

Recommended next extensions:

- graph relations between works
- entity linking
- semantic search
- embeddings
- revision history
- audit logs
- live collaborative editing
