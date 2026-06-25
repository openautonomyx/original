import { randomUUID } from 'node:crypto';
import { createSurrealClient } from './client';

const now = () => new Date().toISOString();

export async function bootstrapPlatformSchema() {
  const db = await createSurrealClient();

  try {
    await db.query(`
      DEFINE TABLE IF NOT EXISTS tenant SCHEMALESS;
      DEFINE INDEX IF NOT EXISTS tenant_slug ON TABLE tenant COLUMNS slug UNIQUE;

      DEFINE TABLE IF NOT EXISTS user SCHEMALESS;
      DEFINE INDEX IF NOT EXISTS user_email ON TABLE user COLUMNS email UNIQUE;

      DEFINE TABLE IF NOT EXISTS membership SCHEMALESS;
      DEFINE INDEX IF NOT EXISTS membership_user_tenant ON TABLE membership COLUMNS user, tenant UNIQUE;

      DEFINE TABLE IF NOT EXISTS session SCHEMALESS;
      DEFINE INDEX IF NOT EXISTS session_token ON TABLE session COLUMNS token UNIQUE;

      DEFINE TABLE IF NOT EXISTS creative_work SCHEMALESS;
      DEFINE INDEX IF NOT EXISTS creative_work_tenant_slug ON TABLE creative_work COLUMNS tenant, slug UNIQUE;
      DEFINE INDEX IF NOT EXISTS creative_work_status ON TABLE creative_work COLUMNS status;
      DEFINE INDEX IF NOT EXISTS creative_work_type ON TABLE creative_work COLUMNS creativeWorkType;

      DEFINE TABLE IF NOT EXISTS content_presence SCHEMALESS;
      DEFINE INDEX IF NOT EXISTS content_presence_work_user ON TABLE content_presence COLUMNS workId, userId UNIQUE;

      DEFINE TABLE IF NOT EXISTS content_revision SCHEMALESS;
      DEFINE INDEX IF NOT EXISTS content_revision_work ON TABLE content_revision COLUMNS workId;

      DEFINE TABLE IF NOT EXISTS media_asset SCHEMALESS;
      DEFINE TABLE IF NOT EXISTS feed SCHEMALESS;
      DEFINE TABLE IF NOT EXISTS automation_event SCHEMALESS;
      DEFINE TABLE IF NOT EXISTS webhook_endpoint SCHEMALESS;
      DEFINE TABLE IF NOT EXISTS schema_entity SCHEMALESS;
    `);

    return { ok: true };
  } finally {
    await db.close();
  }
}

export async function createTenant(input) {
  const db = await createSurrealClient();
  const createdAt = now();

  try {
    const [tenant] = await db.create('tenant', {
      name: input.name,
      slug: input.slug,
      description: input.description || '',
      createdAt,
      updatedAt: createdAt
    });

    return tenant;
  } finally {
    await db.close();
  }
}

export async function listTenants() {
  const db = await createSurrealClient();

  try {
    const [rows] = await db.query('SELECT * FROM tenant ORDER BY createdAt DESC;');
    return rows || [];
  } finally {
    await db.close();
  }
}

export async function createUser(input) {
  const db = await createSurrealClient();
  const createdAt = now();

  try {
    const [user] = await db.create('user', {
      email: input.email,
      name: input.name || '',
      status: 'active',
      createdAt,
      updatedAt: createdAt
    });

    return user;
  } finally {
    await db.close();
  }
}

export async function listUsers() {
  const db = await createSurrealClient();

  try {
    const [rows] = await db.query('SELECT * FROM user ORDER BY createdAt DESC;');
    return rows || [];
  } finally {
    await db.close();
  }
}

export async function createMembership(input) {
  const db = await createSurrealClient();
  const createdAt = now();

  try {
    const [membership] = await db.create('membership', {
      user: input.user,
      tenant: input.tenant,
      role: input.role || 'editor',
      createdAt,
      updatedAt: createdAt
    });

    return membership;
  } finally {
    await db.close();
  }
}

export async function createSession(input) {
  const db = await createSurrealClient();
  const createdAt = now();

  try {
    const [session] = await db.create('session', {
      user: input.user,
      token: input.token || randomUUID(),
      expiresAt: input.expiresAt || new Date(Date.now() + 1000 * 60 * 60 * 24 * 30).toISOString(),
      createdAt
    });

    return session;
  } finally {
    await db.close();
  }
}

export async function createCreativeWorkRecord(input) {
  const db = await createSurrealClient();
  const createdAt = now();
  const type = input.creativeWorkType || input.schema?.['@type'] || 'CreativeWork';

  try {
    const [work] = await db.create('creative_work', {
      tenant: input.tenant,
      slug: input.slug,
      creativeWorkType: type,
      status: input.status || 'draft',
      schema: {
        '@context': 'https://schema.org',
        '@type': type,
        ...(input.schema || {})
      },
      editorState: input.editorState || null,
      workflow: input.workflow || [],
      collaborators: input.collaborators || [],
      revision: 1,
      createdBy: input.createdBy || null,
      updatedBy: input.updatedBy || input.createdBy || null,
      createdAt,
      updatedAt: createdAt
    });

    await createContentRevision(work.id, work, input.createdBy || 'system', 'created');
    return work;
  } finally {
    await db.close();
  }
}

export async function listCreativeWorkRecords(filters = {}) {
  const db = await createSurrealClient();

  try {
    const where = [];
    const params = {};

    if (filters.tenant) {
      where.push('tenant = $tenant');
      params.tenant = filters.tenant;
    }

    if (filters.status) {
      where.push('status = $status');
      params.status = filters.status;
    }

    if (filters.creativeWorkType) {
      where.push('creativeWorkType = $creativeWorkType');
      params.creativeWorkType = filters.creativeWorkType;
    }

    const query = `SELECT * FROM creative_work${where.length ? ` WHERE ${where.join(' AND ')}` : ''} ORDER BY updatedAt DESC;`;
    const [rows] = await db.query(query, params);
    return rows || [];
  } finally {
    await db.close();
  }
}

export async function getCreativeWorkRecord(id) {
  const db = await createSurrealClient();

  try {
    return await db.select(id);
  } finally {
    await db.close();
  }
}

export async function updateCreativeWorkRecord(id, input) {
  const db = await createSurrealClient();
  const existing = await getCreativeWorkRecord(id);
  const nextRevision = (existing?.revision || 1) + 1;

  try {
    const [updated] = await db.merge(id, {
      ...input,
      revision: nextRevision,
      updatedAt: now()
    });

    await createContentRevision(id, updated, input.updatedBy || 'system', 'updated');
    return updated;
  } finally {
    await db.close();
  }
}

export async function transitionCreativeWorkRecord(id, status, actor) {
  const existing = await getCreativeWorkRecord(id);
  const event = {
    status,
    actor: actor || null,
    at: now()
  };

  return updateCreativeWorkRecord(id, {
    status,
    updatedBy: actor || existing?.updatedBy || null,
    publishedAt: status === 'published' ? event.at : existing?.publishedAt,
    workflow: [...(existing?.workflow || []), event],
    schema: {
      ...(existing?.schema || {}),
      dateModified: event.at,
      ...(status === 'published' ? { datePublished: event.at } : {})
    }
  });
}

export async function upsertContentPresence(input) {
  const db = await createSurrealClient();
  const seenAt = now();

  try {
    const [rows] = await db.query(
      'SELECT * FROM content_presence WHERE workId = $workId AND userId = $userId LIMIT 1;',
      { workId: input.workId, userId: input.userId }
    );

    if (rows?.[0]?.id) {
      const [presence] = await db.merge(rows[0].id, {
        name: input.name || input.userId,
        cursor: input.cursor || null,
        status: input.status || 'editing',
        seenAt
      });
      return presence;
    }

    const [presence] = await db.create('content_presence', {
      workId: input.workId,
      userId: input.userId,
      name: input.name || input.userId,
      cursor: input.cursor || null,
      status: input.status || 'editing',
      seenAt,
      createdAt: seenAt
    });

    return presence;
  } finally {
    await db.close();
  }
}

export async function listContentPresence(workId) {
  const db = await createSurrealClient();

  try {
    const [rows] = await db.query(
      'SELECT * FROM content_presence WHERE workId = $workId ORDER BY seenAt DESC;',
      { workId }
    );
    return rows || [];
  } finally {
    await db.close();
  }
}

export async function createContentRevision(workId, snapshot, actor = 'system', reason = 'snapshot') {
  const db = await createSurrealClient();
  const createdAt = now();

  try {
    const [revision] = await db.create('content_revision', {
      workId,
      actor,
      reason,
      snapshot,
      createdAt
    });
    return revision;
  } finally {
    await db.close();
  }
}

export async function listContentRevisions(workId) {
  const db = await createSurrealClient();

  try {
    const [rows] = await db.query(
      'SELECT * FROM content_revision WHERE workId = $workId ORDER BY createdAt DESC;',
      { workId }
    );
    return rows || [];
  } finally {
    await db.close();
  }
}
