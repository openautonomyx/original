# Docker Deployment Guide

## 🐳 Quick Start

### Option 1: Full Stack (Recommended for Development)

```bash
# Clone and navigate
git clone https://github.com/openautonomyx/original.git
cd original

# Start all services
docker-compose up -d

# Initialize database migrations (if needed)
docker exec openautonomyx-app npm run migrate --if-present

# Pull LLM model
docker exec openautonomyx-ollama ollama pull mistral

# View logs
docker-compose logs -f app

# Access the app
open http://localhost:3000
```

### Option 2: App Only (Without Full Stack)

```bash
# Build image
docker build -t openautonomyx:latest .

# Run with environment variables
docker run -d \
  --name openautonomyx \
  -p 3000:3000 \
  -e NODE_ENV=production \
  -e LLM_PROVIDER=ollama \
  -e LLM_API_URL=http://host.docker.internal:11434 \
  openautonomyx:latest

# View logs
docker logs -f openautonomyx

# Stop
docker stop openautonomyx
docker rm openautonomyx
```

---

## 📦 Image Details

### Image Information
- **Base Image:** `node:18-alpine`
- **Size:** ~500MB
- **Security:** Non-root user (nodejs:1001)
- **Health Check:** Built-in `/api/health`

### Included In Image
- ✅ Compiled application (dist/)
- ✅ Static files (public/)
- ✅ Documentation (docs/)
- ✅ SBOM (sbom.xml)
- ✅ License & credits

### Not Included (Use Environment)
- Database (external PostgreSQL)
- Cache (external Redis)
- LLM (Ollama or cloud)
- Secrets (via env vars)

---

## 🔧 Configuration

### Environment Variables

```bash
# Core
NODE_ENV=production
PORT=3000

# Database
DATABASE_TYPE=postgresql
DATABASE_URL=postgresql://user:pass@postgres:5432/openautonomyx

# Cache
REDIS_URL=redis://redis:6379

# LLM Configuration
LLM_PROVIDER=ollama          # ollama, openai, anthropic, azure
LLM_MODEL=mistral            # Model name
OLLAMA_API_URL=http://ollama:11434

# Storage
STORAGE_TYPE=local           # local, s3, azure, gcs
STORAGE_PATH=/data/uploads

# Logging
LOG_LEVEL=info               # debug, info, warn, error
LOG_FORMAT=json

# Authentication
JWT_SECRET=your-secret-key
API_KEY_PREFIX=sk-openautonomyx
```

---

## 🚀 Docker Compose Services

### app
- **Port:** 3000
- **Health Check:** Every 30s
- **Depends On:** postgres, redis, ollama
- **Volumes:** 
  - `/data` - Persistent uploads
  - `/app/uploads` - App uploads directory

### postgres
- **Port:** 5432 (exposed)
- **User:** openautonomyx
- **Password:** secure_password
- **Volume:** postgres_data (persistent)
- **Health:** pg_isready check

### redis
- **Port:** 6379 (exposed)
- **Persistence:** Enabled (appendonly)
- **Volume:** redis_data (persistent)
- **Health:** PING check

### ollama
- **Port:** 11434 (exposed)
- **Volume:** ollama_data (model cache)
- **Default Models:** None (pull manually)

### pgAdmin (Optional)
- **Port:** 5050
- **Default User:** admin@openautonomyx.com
- **Default Pass:** admin
- **Use:** http://localhost:5050

### redis-commander (Optional)
- **Port:** 8081
- **Use:** http://localhost:8081

---

## 🌍 Pull LLM Models

The Ollama service starts empty. Pull models:

```bash
# Mistral (7B, recommended for speed)
docker exec openautonomyx-ollama ollama pull mistral

# LLaMA 2 (7B, balanced)
docker exec openautonomyx-ollama ollama pull llama2

# Neural Chat (4B, dialogue-optimized)
docker exec openautonomyx-ollama ollama pull neural-chat

# View available models
docker exec openautonomyx-ollama ollama list
```

---

## 📊 Common Operations

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f app
docker-compose logs -f postgres
docker-compose logs -f ollama
```

### Database Management
```bash
# Connect to PostgreSQL
docker exec -it openautonomyx-postgres psql -U openautonomyx -d openautonomyx

# Run migrations
docker exec openautonomyx-app npm run migrate

# Backup database
docker exec openautonomyx-postgres pg_dump -U openautonomyx openautonomyx > backup.sql

# Restore database
cat backup.sql | docker exec -i openautonomyx-postgres psql -U openautonomyx openautonomyx
```

### Cache Management
```bash
# Connect to Redis
docker exec -it openautonomyx-redis redis-cli

# Clear all cache
docker exec openautonomyx-redis redis-cli FLUSHALL

# Monitor cache
docker exec openautonomyx-redis redis-cli MONITOR
```

### App Restart
```bash
# Restart single service
docker-compose restart app

# Restart all
docker-compose restart

# Stop all
docker-compose down

# Start again
docker-compose up -d
```

---

## 🔒 Production Deployment

### Security Checklist
- [ ] Change default PostgreSQL password
- [ ] Change default pgAdmin password
- [ ] Set strong JWT_SECRET
- [ ] Use environment-specific .env file
- [ ] Enable HTTPS (reverse proxy)
- [ ] Set up firewall rules
- [ ] Regular backup strategy
- [ ] Monitor container logs
- [ ] Keep images updated

### Production Environment Variables
```bash
NODE_ENV=production
LOG_LEVEL=warn
HTTPS_ENABLED=true
CORS_ORIGIN=https://openautonomyx.com
```

### Production docker-compose
```yaml
# Override: create docker-compose.prod.yml
version: '3.9'
services:
  app:
    image: ghcr.io/openautonomyx/original:latest
    restart: always
    # ... production overrides
```

### Run Production Stack
```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

---

## 📈 Performance Tuning

### Memory Limits
```yaml
app:
  deploy:
    resources:
      limits:
        memory: 512M
      reservations:
        memory: 256M
```

### CPU Limits
```yaml
app:
  deploy:
    resources:
      limits:
        cpus: '1'
```

### Caching Strategy
```bash
# Increase Redis memory
docker exec openautonomyx-redis redis-cli CONFIG SET maxmemory 256mb

# Set eviction policy
docker exec openautonomyx-redis redis-cli CONFIG SET maxmemory-policy allkeys-lru
```

---

## 🆘 Troubleshooting

### App won't start
```bash
# Check logs
docker-compose logs app

# Verify environment variables
docker inspect openautonomyx-app

# Rebuild image
docker-compose build --no-cache app
docker-compose up -d app
```

### Database connection error
```bash
# Check PostgreSQL status
docker-compose ps postgres

# Verify connectivity
docker exec openautonomyx-app ping postgres

# Check connection string
docker exec openautonomyx-app env | grep DATABASE
```

### Out of memory
```bash
# Check usage
docker stats

# Clean up
docker system prune -a

# Increase Docker resource limits
# System Settings → Resources → Memory/CPU
```

### Ollama models not found
```bash
# Ensure Ollama is healthy
docker-compose ps ollama

# Pull model explicitly
docker exec openautonomyx-ollama ollama pull mistral

# Check Ollama connectivity from app
docker exec openautonomyx-app curl http://ollama:11434/api/tags
```

---

## 📚 Advanced Topics

### Custom Networks
```bash
# Create custom bridge network
docker network create openautonomyx-custom

# Use in docker-compose.yml
networks:
  openautonomyx:
    name: openautonomyx-custom
```

### Volume Mounts
```bash
# Mount specific directory
docker run -v /path/on/host:/app/data openautonomyx:latest
```

### Multi-Architecture Builds
```bash
docker buildx build --platform linux/amd64,linux/arm64 -t openautonomyx:latest .
```

### Image Size Optimization
```bash
# Build with BuildKit
DOCKER_BUILDKIT=1 docker build -t openautonomyx:latest .

# Scan for vulnerabilities
docker scan openautonomyx:latest
```

---

## 🌐 Publishing Images

### GitHub Container Registry (GHCR)
```bash
docker tag openautonomyx:latest ghcr.io/openautonomyx/original:latest
docker push ghcr.io/openautonomyx/original:latest
```

### Docker Hub
```bash
docker tag openautonomyx:latest yourusername/openautonomyx:latest
docker push yourusername/openautonomyx:latest
```

### Automatic (GitHub Actions)
- Commits to `main` → automatic push
- Git tags (v1.0.0) → automatic push
- See `.github/workflows/docker.yml`

---

## 📞 Support

- **Docker Docs:** https://docs.docker.com
- **Compose Reference:** https://docs.docker.com/compose/compose-file
- **Ollama Models:** https://ollama.ai/library
- **OpenAutonomyX Docs:** https://openautonomyx.github.io/original

**Last Updated:** June 25, 2026
**Status:** Production Ready
