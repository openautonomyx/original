# Architecture

## Monorepo Structure

```
packages/
├── agents/       - Agent framework and registry
├── platform/     - Main application
├── publications/ - Content management
└── console/      - Deployment tools
```

## Environment

Single environment context for all packages.

## Deployment

All packages deploy together via unified CI/CD pipeline.
