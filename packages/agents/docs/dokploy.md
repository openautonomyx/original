# Deploying with Dokploy

Publishing Platform can be deployed through Dokploy using the existing Dockerfile.

## Recommended Dokploy App Type

Use a Dockerfile-based application.

## Repository

```text
https://github.com/openautonomyx/Publishing-Platform
```

## Branch

```text
main
```

## Build Settings

```text
Dockerfile path: Dockerfile
Build context: .
Exposed port: 3000
```

## Environment Variables

Set these in Dokploy:

```env
NODE_ENV=production
HOST=0.0.0.0
PORT=3000
SURREALDB_URL=http://surrealdb:8000/rpc
SURREALDB_NAMESPACE=publishing_platform
SURREALDB_DATABASE=main
SURREALDB_USERNAME=root
SURREALDB_PASSWORD=change-me
```

For production, replace `SURREALDB_PASSWORD` with a strong secret.

## SurrealDB Service

Create a separate Dokploy service for SurrealDB or use an external SurrealDB instance.

Example Docker image:

```text
surrealdb/surrealdb:latest
```

Example command:

```bash
start --user root --pass change-me rocksdb:/data/database.db
```

Expose SurrealDB internally on:

```text
8000
```

Do not publicly expose the SurrealDB admin endpoint unless it is protected.

## Domain

Point your domain to the Dokploy app, for example:

```text
publishing.openautonomy.ai
```

Dokploy can provision SSL automatically if the domain is configured correctly.

## Healthcheck

The app exposes:

```text
/api/health
```

Use this as the healthcheck path when Dokploy supports custom health checks.

## Deployment Flow

```text
GitHub push to main
  -> Dokploy pulls repo
  -> Dockerfile builds app
  -> container starts on port 3000
  -> app connects to SurrealDB
  -> domain routes traffic to Astro SSR app
```

## Notes

The app currently uses Astro's Node adapter, which is the correct runtime for Dokploy Docker deployments.

The app also includes GitHub Container Registry publishing, but Dokploy can build directly from the GitHub repository using the Dockerfile.
