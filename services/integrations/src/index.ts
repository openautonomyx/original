import express, { Request, Response, NextFunction } from 'express';
import axios from 'axios';
import cors from 'cors';
import { FormatterUtils, EventBus } from '@publishing-platform/core';
import { v4 as uuid } from 'uuid';

const app = express();
const PORT = process.env.PORT || 3010;
const eventBus = new EventBus();

// Types
interface PublishingIntegration {
  id: string;
  name: string;
  type: 'wordpress' | 'medium' | 'substack' | 'canva' | 'twitter' | 'linkedin' | 'facebook' | 'custom';
  isActive: boolean;
  config: Record<string, any>;
  createdAt: Date;
  updatedAt: Date;
}

interface PublishRequest {
  title: string;
  content: string;
  excerpt?: string;
  tags?: string[];
  metadata?: Record<string, any>;
}

interface PublishResponse {
  success: boolean;
  integrationId: string;
  externalId: string;
  url?: string;
  timestamp: Date;
}

// In-memory store
const integrations: Map<string, PublishingIntegration> = new Map();
const publishHistory: PublishResponse[] = [];

// Middleware
app.use(cors());
app.use(express.json());

app.use((req: Request, res: Response, next: NextFunction) => {
  console.log(`[Integrations] ${req.method} ${req.path}`);
  next();
});

// Health check
app.get('/health', (req: Request, res: Response) => {
  res.json({ status: 'ok', service: 'integrations', timestamp: new Date() });
});

// ==================== INTEGRATION MANAGEMENT ====================

// Register new integration
app.post('/api/v1/integrations', (req: Request, res: Response) => {
  try {
    const { name, type, config } = req.body;

    if (!name || !type) {
      return res.status(400).json({ error: 'Name and type required' });
    }

    const integration: PublishingIntegration = {
      id: uuid(),
      name,
      type,
      isActive: true,
      config,
      createdAt: new Date(),
      updatedAt: new Date()
    };

    integrations.set(integration.id, integration);

    eventBus.publish({
      type: 'feature.created',
      source: 'integrations',
      data: { integrationId: integration.id, name, type }
    });

    res.status(201).json(FormatterUtils.createSuccessResponse(integration));
  } catch (error) {
    res.status(500).json(FormatterUtils.createErrorResponse((error as Error).message));
  }
});

// Get all integrations
app.get('/api/v1/integrations', (req: Request, res: Response) => {
  try {
    const all = Array.from(integrations.values());
    res.json(FormatterUtils.createSuccessResponse(all));
  } catch (error) {
    res.status(500).json(FormatterUtils.createErrorResponse((error as Error).message));
  }
});

// Get single integration
app.get('/api/v1/integrations/:id', (req: Request, res: Response) => {
  try {
    const integration = integrations.get(req.params.id);
    if (!integration) {
      return res.status(404).json({ error: 'Integration not found' });
    }
    res.json(FormatterUtils.createSuccessResponse(integration));
  } catch (error) {
    res.status(500).json(FormatterUtils.createErrorResponse((error as Error).message));
  }
});

// Update integration
app.put('/api/v1/integrations/:id', (req: Request, res: Response) => {
  try {
    const integration = integrations.get(req.params.id);
    if (!integration) {
      return res.status(404).json({ error: 'Integration not found' });
    }

    Object.assign(integration, { ...req.body, updatedAt: new Date() });
    integrations.set(req.params.id, integration);

    res.json(FormatterUtils.createSuccessResponse(integration));
  } catch (error) {
    res.status(500).json(FormatterUtils.createErrorResponse((error as Error).message));
  }
});

// Delete integration
app.delete('/api/v1/integrations/:id', (req: Request, res: Response) => {
  try {
    integrations.delete(req.params.id);
    res.json(FormatterUtils.createSuccessResponse({ deleted: true }));
  } catch (error) {
    res.status(500).json(FormatterUtils.createErrorResponse((error as Error).message));
  }
});

// ==================== PUBLISHING ====================

// Publish to integration
app.post('/api/v1/integrations/:id/publish', async (req: Request, res: Response) => {
  try {
    const integration = integrations.get(req.params.id);
    if (!integration) {
      return res.status(404).json({ error: 'Integration not found' });
    }

    const publishData: PublishRequest = req.body;
    let result: PublishResponse | null = null;

    // Route to appropriate publisher
    switch (integration.type) {
      case 'wordpress':
        result = await publishToWordPress(integration, publishData);
        break;
      case 'medium':
        result = await publishToMedium(integration, publishData);
        break;
      case 'substack':
        result = await publishToSubstack(integration, publishData);
        break;
      case 'canva':
        result = await publishToCanva(integration, publishData);
        break;
      case 'twitter':
        result = await publishToTwitter(integration, publishData);
        break;
      case 'linkedin':
        result = await publishToLinkedIn(integration, publishData);
        break;
      case 'facebook':
        result = await publishToFacebook(integration, publishData);
        break;
      default:
        return res.status(400).json({ error: `Unsupported integration type: ${integration.type}` });
    }

    if (result) {
      publishHistory.push(result);
      eventBus.publish({
        type: 'content.published',
        source: 'integrations',
        data: {
          integrationId: integration.id,
          type: integration.type,
          externalId: result.externalId,
          url: result.url
        }
      });
    }

    res.status(201).json(FormatterUtils.createSuccessResponse(result));
  } catch (error) {
    res.status(500).json(FormatterUtils.createErrorResponse((error as Error).message));
  }
});

// ==================== PUBLISHER IMPLEMENTATIONS ====================

async function publishToWordPress(
  integration: PublishingIntegration,
  data: PublishRequest
): Promise<PublishResponse> {
  const { apiUrl, username, password } = integration.config;

  const auth = Buffer.from(`${username}:${password}`).toString('base64');

  const response = await axios.post(`${apiUrl}/wp-json/wp/v2/posts`, {
    title: data.title,
    content: data.content,
    excerpt: data.excerpt,
    status: 'publish',
    tags: data.metadata?.tags || []
  }, {
    headers: {
      'Authorization': `Basic ${auth}`,
      'Content-Type': 'application/json'
    }
  });

  return {
    success: true,
    integrationId: integration.id,
    externalId: response.data.id.toString(),
    url: response.data.link,
    timestamp: new Date()
  };
}

async function publishToMedium(
  integration: PublishingIntegration,
  data: PublishRequest
): Promise<PublishResponse> {
  const { accessToken, publicationId } = integration.config;

  const response = await axios.post(
    `https://api.medium.com/v1/publications/${publicationId}/posts`,
    {
      title: data.title,
      content: data.content,
      contentFormat: 'markdown',
      publishStatus: 'publish'
    },
    {
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json'
      }
    }
  );

  return {
    success: true,
    integrationId: integration.id,
    externalId: response.data.id,
    url: response.data.url,
    timestamp: new Date()
  };
}

async function publishToSubstack(
  integration: PublishingIntegration,
  data: PublishRequest
): Promise<PublishResponse> {
  const { apiKey, publication } = integration.config;

  const response = await axios.post(
    `https://substack.com/api/v1/posts`,
    {
      title: data.title,
      body_markdown: data.content,
      description: data.excerpt,
      published: true
    },
    {
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      }
    }
  );

  return {
    success: true,
    integrationId: integration.id,
    externalId: response.data.id,
    url: response.data.canonical_url,
    timestamp: new Date()
  };
}

async function publishToCanva(
  integration: PublishingIntegration,
  data: PublishRequest
): Promise<PublishResponse> {
  // Canva API for publishing designs
  const { apiKey, designId } = integration.config;

  const response = await axios.post(
    `https://api.canva.com/v1/designs/${designId}/publish`,
    {
      title: data.title,
      description: data.excerpt
    },
    {
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      }
    }
  );

  return {
    success: true,
    integrationId: integration.id,
    externalId: response.data.published_id,
    url: response.data.share_url,
    timestamp: new Date()
  };
}

async function publishToTwitter(
  integration: PublishingIntegration,
  data: PublishRequest
): Promise<PublishResponse> {
  // Twitter/X API v2
  const { bearerToken } = integration.config;

  const response = await axios.post(
    'https://api.twitter.com/2/tweets',
    {
      text: `${data.title}\n\n${data.excerpt || data.content.substring(0, 200)}`
    },
    {
      headers: {
        'Authorization': `Bearer ${bearerToken}`,
        'Content-Type': 'application/json'
      }
    }
  );

  return {
    success: true,
    integrationId: integration.id,
    externalId: response.data.data.id,
    url: `https://twitter.com/user/status/${response.data.data.id}`,
    timestamp: new Date()
  };
}

async function publishToLinkedIn(
  integration: PublishingIntegration,
  data: PublishRequest
): Promise<PublishResponse> {
  // LinkedIn API
  const { accessToken, personId } = integration.config;

  const response = await axios.post(
    'https://api.linkedin.com/v2/articles',
    {
      title: data.title,
      content: data.content,
      description: data.excerpt
    },
    {
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json'
      }
    }
  );

  return {
    success: true,
    integrationId: integration.id,
    externalId: response.data.id,
    url: response.data.articleUrn,
    timestamp: new Date()
  };
}

async function publishToFacebook(
  integration: PublishingIntegration,
  data: PublishRequest
): Promise<PublishResponse> {
  // Facebook Graph API
  const { accessToken, pageId } = integration.config;

  const response = await axios.post(
    `https://graph.facebook.com/v18.0/${pageId}/feed`,
    {
      message: data.title,
      description: data.excerpt,
      link: data.metadata?.url
    },
    {
      params: { access_token: accessToken }
    }
  );

  return {
    success: true,
    integrationId: integration.id,
    externalId: response.data.id,
    url: `https://facebook.com/${response.data.id}`,
    timestamp: new Date()
  };
}

// ==================== PUBLISH HISTORY ====================

app.get('/api/v1/integrations/history', (req: Request, res: Response) => {
  try {
    res.json(FormatterUtils.createSuccessResponse(publishHistory));
  } catch (error) {
    res.status(500).json(FormatterUtils.createErrorResponse((error as Error).message));
  }
});

app.get('/api/v1/integrations/:id/history', (req: Request, res: Response) => {
  try {
    const history = publishHistory.filter(p => p.integrationId === req.params.id);
    res.json(FormatterUtils.createSuccessResponse(history));
  } catch (error) {
    res.status(500).json(FormatterUtils.createErrorResponse((error as Error).message));
  }
});

// Error handling
app.use((err: any, req: Request, res: Response, next: NextFunction) => {
  console.error('Integrations Service Error:', err);
  res.status(500).json(FormatterUtils.createErrorResponse('Internal Server Error'));
});

app.listen(PORT, () => {
  console.log(`🔌 Integrations service running on port ${PORT}`);
  console.log(`📤 API: http://localhost:${PORT}/api/v1/integrations`);
  console.log(`\n✅ Supported platforms:`);
  console.log(`   • WordPress`);
  console.log(`   • Medium`);
  console.log(`   • Substack`);
  console.log(`   • Canva`);
  console.log(`   • Twitter/X`);
  console.log(`   • LinkedIn`);
  console.log(`   • Facebook`);
  console.log(`   • Add more by extending this service\n`);
});
