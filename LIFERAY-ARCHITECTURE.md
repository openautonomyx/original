# OpenAutonomyX with Liferay DXP - End-to-End Architecture

**Complete platform using Liferay as the UI/Portal layer connected to our microservices backend**

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                   Liferay DXP 7.4 (UI Layer)                │
│  (Portal, Sites, Experiences, Content Management)           │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  • Publishing Portal                                        │
│  • Content Management (Native)                              │
│  • Multi-Channel Experiences                                │
│  • Personalization & Segmentation                           │
│  • Mobile App Integration                                   │
│                                                              │
└──────────────────┬──────────────────────────────────────────┘
                   │ REST APIs / GraphQL
                   ↓
┌─────────────────────────────────────────────────────────────┐
│           OpenAutonomyX Microservices Backend                │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Core Services:                                             │
│  • API Gateway (3000)                                       │
│  • Event Bus (3001)                                         │
│  • Blog (3009)                                              │
│  • Integrations (3010) - WordPress, Medium, etc             │
│  • Formats (3011) - EPUB, PDF, Slides, Audio, Video        │
│  • Content Management (3002)                                │
│  • Analytics (3005)                                         │
│  • Optimization (3006)                                      │
│  • And 9+ more modules                                      │
│                                                              │
└──────────────────┬──────────────────────────────────────────┘
                   │
         ┌─────────┼─────────┐
         ↓         ↓         ↓
    PostgreSQL  Redis    Ollama
    (Database)  (Cache)   (Local LLM)
```

---

## Layer Breakdown

### 1. Presentation Layer (Liferay DXP)
**What Users See and Interact With**

```
Liferay Sites/Portals:
├─ Publishing Portal
│  ├─ Create Content (Uses our API)
│  ├─ Manage Blog (Our Blog Service)
│  ├─ Format Converter UI (Calls our Formats Service)
│  ├─ Integrations Manager (Our Integrations Service)
│  └─ Analytics Dashboard (Our Analytics Service)
│
├─ Admin Experience
│  ├─ User Management
│  ├─ Permissions
│  ├─ Segmentation
│  └─ Personalization
│
└─ Public Website
   ├─ Blog Reader
   ├─ Content Showcase
   ├─ Multi-language
   └─ SEO-optimized
```

**Liferay Experiences:**
- Homepage Experience
- Creator Experience
- Admin Experience
- Reader Experience

---

### 2. API/Backend Layer (Our Microservices)

**Liferay calls our REST APIs:**

```typescript
// Liferay Custom Portlets/Pages call our APIs

// Create content via our API
fetch('/api/v1/content/create', {
  method: 'POST',
  body: JSON.stringify({
    title: 'My Post',
    content: 'Markdown content',
    integrations: ['wordpress', 'medium', 'twitter']
  })
});

// Convert to formats
fetch('/api/v1/formats/epub', {
  method: 'POST',
  body: JSON.stringify({ contentId, title, author, content })
});

// Publish to integrations
fetch('/api/v1/integrations/{id}/publish', {
  method: 'POST',
  body: JSON.stringify({ title, content, excerpt })
});
```

---

## Complete End-to-End Flow

### User Journey in Liferay

```
1. User logs into Liferay Portal
   ↓
2. Creator Experience loads
   • Personalized dashboard (using Liferay segments)
   • Recent content
   • Publishing options
   ↓
3. Click "Create New Post"
   • Liferay Content Form
   • Submit to our Content API (3002)
   ↓
4. Click "Convert to Formats"
   • Liferay UI calls our Formats Service (3011)
   • Generates EPUB, PDF, Slides, Audio, Video
   ↓
5. Click "Publish to Platforms"
   • Liferay Integration Panel
   • Selects: WordPress, Medium, Twitter
   • Calls our Integrations Service (3010)
   ↓
6. View Analytics
   • Liferay Dashboard
   • Pulls data from our Analytics Service (3005)
   • Shows performance across all platforms
```

---

## Installation & Setup

### Step 1: Deploy Liferay DXP

```bash
# Using Docker
docker run -d \
  --name liferay \
  -p 8080:8080 \
  -e LIFERAY_JDBC_ONE_URL="jdbc:postgresql://postgres:5432/liferay" \
  -e LIFERAY_JDBC_ONE_DRIVER_CLASS_NAME="org.postgresql.Driver" \
  -e LIFERAY_JDBC_ONE_USERNAME="postgres" \
  -e LIFERAY_JDBC_ONE_PASSWORD="password" \
  liferay/dxp:latest
```

Or use Liferay Cloud:
```
https://console.liferay.cloud/
```

### Step 2: Create Custom Portlets

**Content Creator Portlet:**
```xml
<!-- portlet.xml -->
<portlet>
  <portlet-name>content-creator</portlet-name>
  <display-name>Content Creator</display-name>
  <portlet-class>com.liferay.ContentCreatorPortlet</portlet-class>
  <resource-bundle>content.Language</resource-bundle>
  <supports>
    <mime-type>text/html</mime-type>
    <portlet-mode>view</portlet-mode>
    <portlet-mode>edit</portlet-mode>
  </supports>
</portlet>
```

**Format Converter Portlet:**
```xml
<portlet>
  <portlet-name>format-converter</portlet-name>
  <display-name>Format Converter</display-name>
  <portlet-class>com.liferay.FormatConverterPortlet</portlet-class>
  <supports>
    <mime-type>text/html</mime-type>
    <portlet-mode>view</portlet-mode>
  </supports>
</portlet>
```

### Step 3: Build Portlets

**Liferay Blade CLI:**
```bash
# Create portlet template
blade create -t mvc-portlet \
  -p com.liferay.content \
  content-creator-portlet

# Build
cd content-creator-portlet
./gradlew build

# Deploy
cp build/libs/*.jar $LIFERAY_HOME/deploy/
```

### Step 4: Create Sites & Experiences

**In Liferay Control Panel:**

1. Create Site: "OpenAutonomyX Publishing"
2. Add Pages:
   - /dashboard (Creator Dashboard)
   - /blog (Blog Reader)
   - /create (Content Creator)
   - /formats (Format Converter)
   - /integrations (Publish to Platforms)
   - /analytics (Analytics Dashboard)
   - /admin (Admin Panel)

3. Create Experiences:
   - Creator Experience (for content creators)
   - Reader Experience (for readers)
   - Admin Experience (for administrators)

### Step 5: Configure API Connections

**In Liferay Portal Configuration:**

```groovy
// portal-ext.properties

# OpenAutonomyX Backend URLs
openautonomyx.api.gateway.url=http://localhost:3000
openautonomyx.blog.service.url=http://localhost:3009
openautonomyx.formats.service.url=http://localhost:3011
openautonomyx.integrations.service.url=http://localhost:3010
openautonomyx.analytics.service.url=http://localhost:3005

# Authentication
openautonomyx.api.key=YOUR_API_KEY
openautonomyx.api.secret=YOUR_API_SECRET
```

---

## Portlet Examples

### Content Creator Portlet

```java
package com.liferay.contentcreator;

import com.liferay.portal.kernel.portlet.bridges.mvc.MVCPortlet;
import javax.portlet.ActionRequest;
import javax.portlet.ActionResponse;
import javax.portlet.RenderRequest;
import javax.portlet.RenderResponse;
import org.osgi.service.component.annotations.Component;

@Component(
  immediate = true,
  property = {
    "com.liferay.portlet.display-category=category.publishing",
    "javax.portlet.display-name=Content Creator",
    "javax.portlet.init-param.template-path=/",
    "javax.portlet.init-param.view-template=/view.jsp"
  },
  service = Portlet.class
)
public class ContentCreatorPortlet extends MVCPortlet {

  public void createContent(
    ActionRequest actionRequest,
    ActionResponse actionResponse) throws Exception {

    String title = actionRequest.getParameter("title");
    String content = actionRequest.getParameter("content");

    // Call our OpenAutonomyX API
    HttpClient httpClient = HttpClientBuilder.create().build();
    HttpPost request = new HttpPost("http://localhost:3000/api/v1/content/create");

    String json = "{\"title\":\"" + title + "\",\"content\":\"" + content + "\"}";
    request.setEntity(new StringEntity(json));
    request.setHeader("Content-Type", "application/json");

    HttpResponse response = httpClient.execute(request);
    // Handle response
  }

  public void convertToEpub(
    ActionRequest actionRequest,
    ActionResponse actionResponse) throws Exception {

    String contentId = actionRequest.getParameter("contentId");

    // Call Formats Service
    HttpClient httpClient = HttpClientBuilder.create().build();
    HttpPost request = new HttpPost("http://localhost:3011/api/v1/formats/epub");

    String json = "{\"contentId\":\"" + contentId + "\"}";
    request.setEntity(new StringEntity(json));

    HttpResponse response = httpClient.execute(request);
    // Return download URL
  }
}
```

**JSP View (view.jsp):**

```jsp
<%@ include file="/init.jsp" %>

<div class="content-creator">
  <h2>Create New Content</h2>
  
  <aui:form action="<%= createContentURL %>" method="post">
    <aui:input name="title" label="Title" required="true" />
    <aui:input name="content" label="Content" type="textarea" required="true" />
    <aui:select name="integrations" label="Publish To" multiple="true">
      <aui:option label="WordPress" value="wordpress" />
      <aui:option label="Medium" value="medium" />
      <aui:option label="Twitter" value="twitter" />
      <aui:option label="LinkedIn" value="linkedin" />
    </aui:select>
    <aui:button-row>
      <aui:button type="submit" value="Create Content" />
    </aui:button-row>
  </aui:form>
</div>
```

---

### Format Converter Portlet

```java
@Component(
  immediate = true,
  property = {
    "com.liferay.portlet.display-category=category.publishing",
    "javax.portlet.display-name=Format Converter",
    "javax.portlet.init-param.view-template=/formats.jsp"
  },
  service = Portlet.class
)
public class FormatConverterPortlet extends MVCPortlet {

  public void convertFormat(
    ActionRequest actionRequest,
    ActionResponse actionResponse) throws Exception {

    String contentId = actionRequest.getParameter("contentId");
    String format = actionRequest.getParameter("format"); // epub, pdf, slides, audio, video

    String endpoint = "http://localhost:3011/api/v1/formats/" + format;

    // Call Formats Service
    HttpClient httpClient = HttpClientBuilder.create().build();
    HttpPost request = new HttpPost(endpoint);

    String json = "{\"contentId\":\"" + contentId + "\"}";
    request.setEntity(new StringEntity(json));

    HttpResponse response = httpClient.execute(request);
    // Return download link to user
  }
}
```

**JSP (formats.jsp):**

```jsp
<div class="format-converter">
  <h2>Convert Content</h2>
  
  <div class="format-grid">
    <div class="format-card">
      <h3>📚 EPUB</h3>
      <p>E-books for Kindle, Kobo</p>
      <form action="<%= convertFormatURL %>" method="post">
        <input type="hidden" name="format" value="epub" />
        <input type="hidden" name="contentId" value="<%= contentId %>" />
        <button type="submit">Convert to EPUB</button>
      </form>
    </div>
    
    <div class="format-card">
      <h3>📊 Slides</h3>
      <p>PowerPoint presentations</p>
      <form action="<%= convertFormatURL %>" method="post">
        <input type="hidden" name="format" value="slides" />
        <input type="hidden" name="contentId" value="<%= contentId %>" />
        <button type="submit">Generate Slides</button>
      </form>
    </div>
    
    <div class="format-card">
      <h3>📄 PDF</h3>
      <p>Professional documents</p>
      <form action="<%= convertFormatURL %>" method="post">
        <input type="hidden" name="format" value="pdf" />
        <input type="hidden" name="contentId" value="<%= contentId %>" />
        <button type="submit">Export PDF</button>
      </form>
    </div>

    <div class="format-card">
      <h3>🎧 Audio</h3>
      <p>Podcasts & audiobooks</p>
      <form action="<%= convertFormatURL %>" method="post">
        <input type="hidden" name="format" value="audio" />
        <input type="hidden" name="contentId" value="<%= contentId %>" />
        <button type="submit">Generate Audio</button>
      </form>
    </div>

    <div class="format-card">
      <h3>🎬 Video</h3>
      <p>Video content</p>
      <form action="<%= convertFormatURL %>" method="post">
        <input type="hidden" name="format" value="video" />
        <input type="hidden" name="contentId" value="<%= contentId %>" />
        <button type="submit">Create Video</button>
      </form>
    </div>

    <div class="format-card">
      <h3>🌐 HTML</h3>
      <p>Interactive web pages</p>
      <form action="<%= convertFormatURL %>" method="post">
        <input type="hidden" name="format" value="html" />
        <input type="hidden" name="contentId" value="<%= contentId %>" />
        <button type="submit">Generate HTML</button>
      </form>
    </div>
  </div>
</div>
```

---

### Integrations Portlet

```java
@Component(
  immediate = true,
  property = {
    "com.liferay.portlet.display-category=category.publishing",
    "javax.portlet.display-name=Integrations Manager",
    "javax.portlet.init-param.view-template=/integrations.jsp"
  },
  service = Portlet.class
)
public class IntegrationsPortlet extends MVCPortlet {

  public void publishToIntegration(
    ActionRequest actionRequest,
    ActionResponse actionResponse) throws Exception {

    String integrationId = actionRequest.getParameter("integrationId");
    String title = actionRequest.getParameter("title");
    String content = actionRequest.getParameter("content");

    // Call Integrations Service
    String endpoint = "http://localhost:3010/api/v1/integrations/" + integrationId + "/publish";

    HttpClient httpClient = HttpClientBuilder.create().build();
    HttpPost request = new HttpPost(endpoint);

    String json = "{\"title\":\"" + title + "\",\"content\":\"" + content + "\"}";
    request.setEntity(new StringEntity(json));

    HttpResponse response = httpClient.execute(request);
    // Show success/error message
  }
}
```

---

## Liferay Experiences in Action

### Creator Experience
```
[ Publishing Dashboard ]
┌──────────────────────────────────┐
│ Welcome Back, Creator!           │
│                                  │
│ Recent Posts:                    │
│ • "Getting Started" - Draft      │
│ • "Platform Overview" - Published│
│                                  │
│ Quick Actions:                   │
│ [+ Create Post] [Formats] [Publish]
│                                  │
│ Analytics:                       │
│ • 1.2K views this week          │
│ • 45 new subscribers            │
│ • 12 shares across platforms    │
└──────────────────────────────────┘
```

### Reader Experience
```
[ Blog Reader ]
┌──────────────────────────────────┐
│ 📚 OpenAutonomyX Publishing      │
│                                  │
│ Latest Posts:                    │
│ • Getting Started                │
│ • Platform Overview              │
│ • Multi-Format Publishing        │
│                                  │
│ [Available as: 📄 📚 🎧 🎬]      │
│ [Share: Twitter LinkedIn]        │
└──────────────────────────────────┘
```

### Admin Experience
```
[ Admin Control Panel ]
┌──────────────────────────────────┐
│ System Management                │
│ • Users & Permissions            │
│ • Service Status (21 services)   │
│ • API Connections                │
│ • Analytics & Reports            │
│ • Security & Backups             │
└──────────────────────────────────┘
```

---

## Multi-Channel Publishing in Liferay

### Publishing Workflow
```
Liferay Content
    ↓
Create in Liferay Portal
    ↓
Convert Formats (EPUB, PDF, Slides, Audio, Video)
    ↓
Publish to Integrations (WordPress, Medium, Twitter, LinkedIn)
    ↓
Multi-Channel Distribution:
├─ WordPress Blog
├─ Medium Articles
├─ Substack Newsletter
├─ Twitter Threads
├─ LinkedIn Posts
└─ YouTube Videos
```

---

## Deployment Architecture

```
┌─────────────────────────────────────┐
│      publishing.openautonomyx.com    │
├─────────────────────────────────────┤
│                                     │
│  Liferay DXP (Port 8080)            │
│  • Portal & Sites                   │
│  • Content Management               │
│  • Personalization                  │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  OpenAutonomyX Services (3000-3011) │
│  • API Gateway                      │
│  • Blog Service                     │
│  • Formats Service                  │
│  • Integrations Service             │
│  • Content Management               │
│  • Analytics                        │
│  • +15 more services                │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  Infrastructure                     │
│  • PostgreSQL (5432)                │
│  • Redis (6379)                     │
│  • Elasticsearch (9200)             │
│  • MinIO (9000)                     │
│  • Ollama (11434)                   │
│                                     │
└─────────────────────────────────────┘
```

---

## Docker Compose - Full Stack

```yaml
version: '3.9'

services:
  # Liferay Portal
  liferay:
    image: liferay/dxp:latest
    container_name: pp-liferay
    ports:
      - "8080:8080"
    environment:
      LIFERAY_JDBC_ONE_URL: jdbc:postgresql://postgres:5432/liferay
      LIFERAY_JDBC_ONE_DRIVER_CLASS_NAME: org.postgresql.Driver
      LIFERAY_JDBC_ONE_USERNAME: postgres
      LIFERAY_JDBC_ONE_PASSWORD: password
    depends_on:
      - postgres
    networks:
      - pp-network
    restart: unless-stopped

  # Backend Services (same as before)
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: publishing_platform
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - pp-network

  api-gateway:
    build: ./services/api-gateway
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: postgresql://postgres:password@postgres:5432/publishing_platform
    depends_on:
      - postgres
    networks:
      - pp-network

  blog:
    build: ./services/blog
    ports:
      - "3009:3009"
    depends_on:
      - postgres
    networks:
      - pp-network

  integrations:
    build: ./services/integrations
    ports:
      - "3010:3010"
    networks:
      - pp-network

  formats:
    build: ./services/formats
    ports:
      - "3011:3011"
    networks:
      - pp-network

  # ... other services

volumes:
  postgres_data:

networks:
  pp-network:
    driver: bridge
```

---

## Benefits of Liferay + OpenAutonomyX

✅ **Best of Both Worlds:**
- Liferay's powerful portal & personalization
- Our lightweight, modular microservices
- No bloat, full control

✅ **Enterprise Ready:**
- Multi-tenant support
- Role-based permissions
- Audit logging
- Backup/recovery

✅ **Multi-Channel Publishing:**
- Create once in Liferay
- Publish everywhere via our services
- Unified analytics

✅ **Scalability:**
- Liferay handles UI
- Our services scale independently
- Easy to add/remove services

✅ **Flexibility:**
- Custom portlets for specific needs
- Liferay Experiences for personalization
- Full REST API access to our backend

---

## Next Steps

1. ☐ Deploy Liferay DXP
2. ☐ Create portlets for Content Creator
3. ☐ Create portlets for Format Converter
4. ☐ Create portlets for Integrations
5. ☐ Create portlets for Analytics
6. ☐ Build Experiences (Creator, Reader, Admin)
7. ☐ Set up API connections to backend
8. ☐ Create deployment package
9. ☐ Go live!

---

**End-to-End Platform Built!** 🚀

Liferay Portal + OpenAutonomyX Services = Complete Publishing Platform
