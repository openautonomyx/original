// @publishing-platform/core - Shared Library
// package.json structure + main exports

/**
 * PACKAGE.JSON
 */
export const packageJson = {
  name: "@publishing-platform/core",
  version: "1.0.0",
  description: "Shared types, utilities, auth, and event bus for Publishing Platform",
  main: "dist/index.js",
  types: "dist/index.d.ts",
  scripts: {
    build: "tsc",
    test: "jest",
    publish: "npm publish --access public"
  },
  dependencies: {
    "uuid": "^9.0.0",
    "jsonwebtoken": "^9.0.0"
  },
  devDependencies: {
    "@types/node": "^20.0.0",
    "typescript": "^5.2.0",
    "jest": "^29.7.0",
    "ts-jest": "^29.1.0"
  }
};

/**
 * src/types/index.ts - All shared types
 */
export interface GartnerCategory {
  id: string;
  marketName: string;
  quadrant: 'leader' | 'visionary' | 'challenger' | 'niche';
  industry: string;
  vertical: string;
  vendor?: string;
  score?: number;
  capabilities: string[];
  tags: string[];
  createdAt: Date;
  updatedAt: Date;
}

export interface User {
  id: string;
  email: string;
  name: string;
  roles: Role[];
  permissions: Permission[];
  metadata?: Record<string, any>;
  createdAt: Date;
  updatedAt: Date;
}

export type Role = 'admin' | 'creator' | 'analyst' | 'designer' | 'viewer' | 'guest';
export type Permission =
  | 'content:create'
  | 'content:read'
  | 'content:update'
  | 'content:delete'
  | 'content:publish'
  | 'analytics:read'
  | 'analytics:export'
  | 'admin:access';

export interface JWTPayload {
  userId: string;
  email: string;
  roles: Role[];
  permissions: Permission[];
  iat: number;
  exp: number;
}

export interface Event {
  id: string;
  type: EventType;
  timestamp: Date;
  source: string; // module name
  correlationId?: string;
  data: Record<string, any>;
  metadata?: Record<string, any>;
}

export type EventType =
  | 'content.created'
  | 'content.updated'
  | 'content.published'
  | 'content.unpublished'
  | 'content.deleted'
  | 'analytics.event'
  | 'optimization.recommendation'
  | 'skill.created'
  | 'skill.updated'
  | 'feature.created';

export interface CreateContentDTO {
  title: string;
  description: string;
  body: string;
  type: 'blog' | 'whitepaper' | 'case-study' | 'guide' | 'tutorial';
  tags: string[];
  gartnerCategoryId?: string;
  metadata?: {
    seo?: { title: string; description: string; keywords: string[] };
    featured?: boolean;
  };
}

export interface UpdateContentDTO extends Partial<CreateContentDTO> {}

export interface PaginationParams {
  page: number;
  limit: number;
  sort?: string;
  filter?: Record<string, any>;
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  timestamp: Date;
}

export interface ApiError {
  code: string;
  message: string;
  statusCode: number;
  details?: Record<string, any>;
}

/**
 * src/auth/index.ts - Authentication service
 */
export class AuthService {
  constructor(private jwtSecret: string) {}

  generateToken(user: User, expiresIn: string = '24h'): string {
    const payload: JWTPayload = {
      userId: user.id,
      email: user.email,
      roles: user.roles,
      permissions: user.permissions,
      iat: Math.floor(Date.now() / 1000),
      exp: Math.floor(Date.now() / 1000) + (24 * 60 * 60) // 24 hours
    };

    return require('jsonwebtoken').sign(payload, this.jwtSecret);
  }

  verifyToken(token: string): JWTPayload {
    try {
      return require('jsonwebtoken').verify(token, this.jwtSecret) as JWTPayload;
    } catch (error) {
      throw new Error('Invalid token');
    }
  }

  hasPermission(token: JWTPayload, required: Permission): boolean {
    return token.permissions.includes(required) || token.roles.includes('admin');
  }

  hasRole(token: JWTPayload, required: Role): boolean {
    return token.roles.includes(required) || token.roles.includes('admin');
  }

  extractToken(authHeader?: string): string | null {
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return null;
    }
    return authHeader.substring(7);
  }
}

/**
 * src/events/index.ts - Event bus for service communication
 */
export class EventBus {
  private handlers: Map<EventType, Array<(event: Event) => Promise<void>>> = new Map();
  private eventHistory: Event[] = [];
  private maxHistorySize = 1000;

  subscribe(eventType: EventType, handler: (event: Event) => Promise<void>): () => void {
    if (!this.handlers.has(eventType)) {
      this.handlers.set(eventType, []);
    }

    this.handlers.get(eventType)!.push(handler);

    // Return unsubscribe function
    return () => {
      const handlers = this.handlers.get(eventType)!;
      const index = handlers.indexOf(handler);
      if (index > -1) {
        handlers.splice(index, 1);
      }
    };
  }

  async publish(event: Omit<Event, 'id' | 'timestamp'>): Promise<void> {
    const fullEvent: Event = {
      ...event,
      id: require('uuid').v4(),
      timestamp: new Date()
    };

    // Store in history
    this.eventHistory.push(fullEvent);
    if (this.eventHistory.length > this.maxHistorySize) {
      this.eventHistory.shift();
    }

    // Call all handlers
    const handlers = this.handlers.get(event.type) || [];
    await Promise.all(handlers.map(h => h(fullEvent).catch(console.error)));
  }

  getHistory(eventType?: EventType, limit: number = 100): Event[] {
    let filtered = this.eventHistory;
    if (eventType) {
      filtered = filtered.filter(e => e.type === eventType);
    }
    return filtered.slice(-limit);
  }

  clearHistory(): void {
    this.eventHistory = [];
  }
}

/**
 * src/utils/index.ts - Utility functions
 */
export class ValidationUtils {
  static isValidEmail(email: string): boolean {
    const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return re.test(email);
  }

  static isValidUUID(uuid: string): boolean {
    const re = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    return re.test(uuid);
  }

  static sanitizeString(str: string): string {
    return str.trim().replace(/[<>]/g, '');
  }

  static validatePagination(page?: number, limit?: number): { page: number; limit: number } {
    return {
      page: Math.max(1, page || 1),
      limit: Math.max(1, Math.min(100, limit || 20))
    };
  }
}

export class FormatterUtils {
  static formatDate(date: Date, format: string = 'ISO'): string {
    if (format === 'ISO') {
      return date.toISOString();
    }
    return date.toString();
  }

  static formatError(error: unknown): ApiError {
    if (error instanceof Error) {
      return {
        code: 'INTERNAL_ERROR',
        message: error.message,
        statusCode: 500
      };
    }
    return {
      code: 'UNKNOWN_ERROR',
      message: 'An unknown error occurred',
      statusCode: 500
    };
  }

  static createSuccessResponse<T>(data: T): ApiResponse<T> {
    return {
      success: true,
      data,
      timestamp: new Date()
    };
  }

  static createErrorResponse(message: string): ApiResponse<null> {
    return {
      success: false,
      error: message,
      timestamp: new Date()
    };
  }
}

/**
 * src/middleware/index.ts - Middleware factories
 */
export function createAuthMiddleware(authService: AuthService) {
  return (authHeader?: string) => {
    const token = authService.extractToken(authHeader);
    if (!token) throw new Error('No token provided');
    return authService.verifyToken(token);
  };
}

export function createRoleMiddleware(authService: AuthService, requiredRole: Role) {
  return (payload: JWTPayload) => {
    if (!authService.hasRole(payload, requiredRole)) {
      throw new Error(`Required role: ${requiredRole}`);
    }
  };
}

export function createPermissionMiddleware(authService: AuthService, requiredPermission: Permission) {
  return (payload: JWTPayload) => {
    if (!authService.hasPermission(payload, requiredPermission)) {
      throw new Error(`Required permission: ${requiredPermission}`);
    }
  };
}

/**
 * src/index.ts - Main exports
 */
export {
  AuthService,
  EventBus,
  ValidationUtils,
  FormatterUtils,
  createAuthMiddleware,
  createRoleMiddleware,
  createPermissionMiddleware
};

export * from './types/index';
