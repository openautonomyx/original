# Publishing Integrations - Plugin Architecture

Enable users to publish to **any platform** with their own integrations.

**Service:** `@publishing-platform/integrations`
**Port:** `3010`

---

## Architecture

```
OpenAutonomyX Platform
├── Content Management
├── Blog Service (Internal)
├── WordPress Blog (External - yours)
└── Integrations Service ← Users plugin their publishing destinations
    ├── WordPress
    ├── Medium
    ├── Substack
    ├── Canva
    ├── Twitter/X
    ├── LinkedIn
    ├── Facebook
    └── Custom (extensible)
```

---

## Setup Your Blog on WordPress

### Option 1: Use Your Hostinger Account (Recommended)

1. **In Hostinger Dashboard:**
   - Click "WordPress"
   - Install on `openautonomyx.com/blog` or `blog.openautonomyx.com`
   - Get WordPress admin access

2. **Get WordPress API Credentials:**
   - Admin → Settings → Permalinks → Ensure "Post name" selected
   - Plugins → Add "REST API" plugin
   - Get your site URL and admin username/password

3. **Connect to OpenAutonomyX:**
   ```bash
   curl -X POST http://localhost:3010/api/v1/integrations \
     -H "Content-Type: application/json" \
     -d '{
       "name": "My WordPress Blog",
       "type": "wordpress",
       "config": {
         "apiUrl": "https://openautonomyx.com/blog",
         "username": "admin",
         "password": "your-app-password"
       }
     }'
   ```

### Option 2: Self-Hosted WordPress

```bash
# Docker compose it
docker run -d \
  -e WORDPRESS_DB_HOST=postgres:5432 \
  -e WORDPRESS_DB_NAME=wordpress \
  -e WORDPRESS_DB_USER=wordpress \
  -e WORDPRESS_DB_PASSWORD=password \
  -p 8080:80 \
  wordpress:latest
```

---

## Register Publishing Integrations

### Add WordPress Integration

```bash
curl -X POST http://localhost:3010/api/v1/integrations \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Main Blog",
    "type": "wordpress",
    "config": {
      "apiUrl": "https://openautonomyx.com/blog",
      "username": "admin",
      "password": "wp_app_password_here"
    }
  }'
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "integration-uuid",
    "name": "Main Blog",
    "type": "wordpress",
    "isActive": true,
    "config": { "apiUrl": "..." },
    "createdAt": "2026-06-26T..."
  }
}
```

### Add Medium Integration

```bash
curl -X POST http://localhost:3010/api/v1/integrations \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Medium Publication",
    "type": "medium",
    "config": {
      "accessToken": "medium-api-token",
      "publicationId": "publication-id"
    }
  }'
```

### Add Substack Integration

```bash
curl -X POST http://localhost:3010/api/v1/integrations \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Substack Newsletter",
    "type": "substack",
    "config": {
      "apiKey": "substack-api-key",
      "publication": "your-substack"
    }
  }'
```

### Add Twitter Integration

```bash
curl -X POST http://localhost:3010/api/v1/integrations \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Twitter Account",
    "type": "twitter",
    "config": {
      "bearerToken": "twitter-api-bearer-token"
    }
  }'
```

### Add LinkedIn Integration

```bash
curl -X POST http://localhost:3010/api/v1/integrations \
  -H "Content-Type: application/json" \
  -d '{
    "name": "LinkedIn Profile",
    "type": "linkedin",
    "config": {
      "accessToken": "linkedin-access-token",
      "personId": "person-id"
    }
  }'
```

---

## Publish to Integrations

### Publish Post to WordPress

```bash
curl -X POST http://localhost:3010/api/v1/integrations/{integration-id}/publish \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Getting Started with OpenAutonomyX",
    "content": "## Introduction\n\nComplete markdown content...",
    "excerpt": "Short summary of the post",
    "tags": ["guide", "openautonomyx"]
  }'
```

**Response:**
```json
{
  "success": true,
  "data": {
    "success": true,
    "integrationId": "integration-uuid",
    "externalId": "12345",
    "url": "https://openautonomyx.com/blog/2026/06/getting-started",
    "timestamp": "2026-06-26T..."
  }
}
```

### Publish to Multiple Platforms (1-Click)

```bash
# Create content once, publish to all
CONTENT='{
  "title": "My Great Post",
  "content": "Full content in markdown...",
  "excerpt": "Summary...",
  "tags": ["business"]
}'

# Publish to all integrations
for INT_ID in $(curl -s http://localhost:3010/api/v1/integrations | jq -r '.data[].id'); do
  curl -X POST http://localhost:3010/api/v1/integrations/$INT_ID/publish \
    -H "Content-Type: application/json" \
    -d "$CONTENT"
done
```

---

## API Reference

### Integration Management

```
GET    /api/v1/integrations              → List all integrations
GET    /api/v1/integrations/{id}         → Get single integration
POST   /api/v1/integrations              → Register new integration
PUT    /api/v1/integrations/{id}         → Update integration
DELETE /api/v1/integrations/{id}         → Remove integration
```

### Publishing

```
POST   /api/v1/integrations/{id}/publish → Publish to platform
GET    /api/v1/integrations/history      → Publish history (all)
GET    /api/v1/integrations/{id}/history → History (single integration)
```

---

## Getting API Credentials

### WordPress
1. Admin Dashboard → Users → Your Profile
2. Scroll to "Application Passwords"
3. Create app password for "OpenAutonomyX"
4. Copy and use as password

### Medium
1. Settings → Security & Privacy
2. Scroll to "Integration Tokens"
3. Generate token → use as `accessToken`

### Substack
1. Settings → Account → API
2. Generate API key

### Twitter
1. Twitter Developer Portal → Keys & Tokens
2. Copy Bearer Token

### LinkedIn
1. LinkedIn App Admin → Auth
2. Generate Access Token

### Canva
1. Canva Developers → Create App
2. Get API Key

### Facebook
1. Meta Developers → Your Apps → Tokens
2. Get Page Access Token

---

## Extend with Custom Integrations

Add new publisher in `src/index.ts`:

```typescript
// Add to switch statement
case 'my-platform':
  result = await publishToMyPlatform(integration, publishData);
  break;

// Implement publisher
async function publishToMyPlatform(
  integration: PublishingIntegration,
  data: PublishRequest
): Promise<PublishResponse> {
  // Call your platform's API
  const response = await axios.post(
    'https://my-platform.com/api/publish',
    { title: data.title, content: data.content },
    { headers: { 'Authorization': `Bearer ${integration.config.apiKey}` } }
  );

  return {
    success: true,
    integrationId: integration.id,
    externalId: response.data.id,
    url: response.data.url,
    timestamp: new Date()
  };
}
```

---

## Complete Workflow

```
User → OpenAutonomyX Platform
       ├─ Writes post
       ├─ Adds metadata (tags, category)
       ├─ Selects integrations to publish to
       └─ Click "Publish"
                 ↓
            Integrations Service
             ├─ WordPress Blog ✓
             ├─ Medium ✓
             ├─ Substack ✓
             ├─ Twitter ✓
             └─ LinkedIn ✓
                 ↓
            Events Published
             ├─ content.published
             ├─ analytics.event (tracking)
             └─ optimization.recommendation
```

---

## Docker Compose

```yaml
integrations:
  build:
    context: ./services/integrations
    dockerfile: Dockerfile
  container_name: pp-integrations
  ports:
    - "3010:3010"
  environment:
    NODE_ENV: development
    PORT: 3010
    SERVICE_NAME: integrations
    EVENT_BUS_URL: http://event-bus:3001
  depends_on:
    - event-bus
  networks:
    - pp-network
  restart: unless-stopped
```

---

## Platform Overview

**20 Total Services:**
- 5 Infrastructure
- 2 Core
- 9 Business Modules
- 1 Blog (internal)
- 1 **Integrations** ← NEW
- 2 Additional (monitoring)

**Blog Strategy:**
- **Internal Blog:** Our `/blog` service (for demos)
- **Your Blog:** WordPress (on Hostinger or self-hosted)
- **Integrations:** Connect your blog + platform to any publishing destination

---

**Status:** ✅ Ready to Plugin

Add your WordPress blog + any other platforms!
