# WordPress Blog Setup on Hostinger

## Step 1: Create Subdomain ✅ (You're Here)

**In your Hostinger Dashboard:**

1. **Subdomain:** `blog`
2. **Domain:** `publishing.openautonomyx.com`
3. **Checkboxes:**
   - ✅ Custom folder for subdomain (checked)
   - ✅ Use public_html directory (checked)
4. **Click:** `Create` button

This creates: `blog.publishing.openautonomyx.com`

---

## Step 2: Install WordPress

**After subdomain is created:**

1. Go to **WordPress** (left sidebar)
2. Click **Install WordPress**
3. Select subdomain: `blog.publishing.openautonomyx.com`
4. Fill in:
   - Site title: "OpenAutonomyX Blog"
   - Admin username: `admin` (or your choice)
   - Admin password: (strong password)
   - Admin email: `thefractionalpm@gmail.com`
5. Click **Install**

Wait 5-10 minutes for installation to complete.

---

## Step 3: Get WordPress API Credentials

**After WordPress is installed:**

1. Go to: `https://blog.publishing.openautonomyx.com/wp-admin`
2. Login with credentials from Step 2
3. Go to: **Users** → **Your Profile**
4. Scroll down to: **Application Passwords**
5. Create new password:
   - App Name: `OpenAutonomyX Platform`
   - Click **Generate Password**
6. **Copy and save** the generated password

You'll use this for connecting to the integrations service.

---

## Step 4: Connect to Platform

**Register WordPress integration in OpenAutonomyX:**

```bash
curl -X POST http://localhost:3010/api/v1/integrations \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Blog - OpenAutonomyX",
    "type": "wordpress",
    "config": {
      "apiUrl": "https://blog.publishing.openautonomyx.com",
      "username": "admin",
      "password": "PASTE_APP_PASSWORD_HERE"
    }
  }'
```

**Response Example:**
```json
{
  "success": true,
  "data": {
    "id": "a1b2c3d4-...",
    "name": "Blog - OpenAutonomyX",
    "type": "wordpress",
    "isActive": true,
    "config": { "apiUrl": "https://blog.openautonomyx.com", ... },
    "createdAt": "2026-06-26T..."
  }
}
```

**Save the `id` for publishing.**

---

## Step 5: Publish Content

**Publish a post to your WordPress blog:**

```bash
curl -X POST http://localhost:3010/api/v1/integrations/{integration-id}/publish \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Welcome to OpenAutonomyX",
    "content": "## Introduction\n\nThis is our first blog post using the integrated publishing platform...",
    "excerpt": "Learn how to use OpenAutonomyX for vendor-neutral creative publishing",
    "tags": ["welcome", "openautonomyx", "publishing"]
  }'
```

**Response:**
```json
{
  "success": true,
  "data": {
    "success": true,
    "integrationId": "a1b2c3d4-...",
    "externalId": "42",
    "url": "https://blog.publishing.openautonomyx.com/2026/06/welcome-to-openautonomyx/",
    "timestamp": "2026-06-26T..."
  }
}
```

---

## Step 6: Add More Integrations

Now you can add:
- **Medium** (for broader distribution)
- **Substack** (for newsletter)
- **Twitter** (for social sharing)
- **LinkedIn** (for professional network)
- **Facebook** (for business page)

**Example - Add Medium:**

```bash
curl -X POST http://localhost:3010/api/v1/integrations \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Medium Publication",
    "type": "medium",
    "config": {
      "accessToken": "your-medium-api-token",
      "publicationId": "your-publication-id"
    }
  }'
```

Then publish with one command to multiple platforms!

---

## Architecture After Setup

```
publishing.openautonomyx.com/
├── /                    → OpenAutonomyX Platform
│   ├── /api/*          → Services
│   ├── /admin          → Admin Panel
│   └── /blog/*         → Internal blog API
│
├── blog.publishing.openautonomyx.com/ → Your WordPress Blog
│   ├── /wp-admin/      → WordPress Admin
│   ├── /               → Blog Frontend
│   └── /wp-json/*      → REST API
│
└── Integrations Service (3010)
    ├── WordPress (blog.publishing.openautonomyx.com)
    ├── Medium
    ├── Substack
    ├── Twitter
    └── LinkedIn
```

---

## API Reference

### List Integrations
```bash
curl http://localhost:3010/api/v1/integrations
```

### Get Single Integration
```bash
curl http://localhost:3010/api/v1/integrations/{id}
```

### Publish to Integration
```bash
curl -X POST http://localhost:3010/api/v1/integrations/{id}/publish \
  -H "Content-Type: application/json" \
  -d '{ "title": "...", "content": "...", ... }'
```

### View Publish History
```bash
curl http://localhost:3010/api/v1/integrations/{id}/history
```

---

## Troubleshooting

### "Invalid credentials"
- Check username and password
- Regenerate Application Password in WordPress

### "API not enabled"
- WordPress → Plugins → Ensure "REST API" is available
- Check WordPress version (must be 4.7+)

### "Connection refused"
- Ensure WordPress is fully installed
- Check domain is accessible: `https://blog.openautonomyx.com/wp-json/`

### "Post creation failed"
- Check excerpt length (not too long)
- Ensure user has "publish_posts" permission
- Check tags are valid

---

## Publishing Workflow

**Step 1: Write in Platform**
- `publishing.openautonomyx.com` - OpenAutonomyX content editor

**Step 2: Select Destinations**
- ☑️ WordPress Blog (blog.publishing.openautonomyx.com)
- ☑️ Medium
- ☑️ Twitter
- ☑️ LinkedIn

**Step 3: Click Publish**
- One-click to all platforms!

**Step 4: Track Performance**
- View publish history
- Analytics from each platform
- Monitor engagement

---

## Complete Setup Checklist

- [ ] Create subdomain `blog.openautonomyx.com`
- [ ] Install WordPress on subdomain
- [ ] Get WordPress API credentials
- [ ] Start integrations service (port 3010)
- [ ] Register WordPress integration in platform
- [ ] Test publish to blog
- [ ] Add Medium integration
- [ ] Add Twitter integration
- [ ] Add LinkedIn integration
- [ ] Create multi-platform publish workflow

---

**Status:** Ready to Click "Create" and setup blog! 🚀
