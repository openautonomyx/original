import type { CreativeWork } from '@publishing-platform/schema';
import { createSurrealClient } from './client';

export interface StoredCreativeWork {
  id?: string;
  tenant?: string;
  slug?: string;
  status?: 'draft' | 'review' | 'published' | 'archived';
  schema: CreativeWork;
  createdAt?: string;
  updatedAt?: string;
}

export async function bootstrapCreativeWorkSchema(): Promise<void> {
  const db = await createSurrealClient();

  try {
    await db.query(`
      DEFINE TABLE IF NOT EXISTS creative_work SCHEMALESS;
      DEFINE INDEX IF NOT EXISTS creative_work_slug ON TABLE creative_work COLUMNS tenant, slug UNIQUE;
      DEFINE INDEX IF NOT EXISTS creative_work_status ON TABLE creative_work COLUMNS status;
      DEFINE INDEX IF NOT EXISTS creative_work_type ON TABLE creative_work COLUMNS schema['@type'];
    `);
  } finally {
    await db.close();
  }
}

export async function listCreativeWorks(tenant?: string): Promise<StoredCreativeWork[]> {
  const db = await createSurrealClient();

  try {
    const [rows] = await db.query<StoredCreativeWork[][]>(
      tenant
        ? 'SELECT * FROM creative_work WHERE tenant = $tenant ORDER BY updatedAt DESC;'
        : 'SELECT * FROM creative_work ORDER BY updatedAt DESC;',
      { tenant }
    );

    return rows || [];
  } finally {
    await db.close();
  }
}

export async function getCreativeWork(id: string): Promise<StoredCreativeWork | null> {
  const db = await createSurrealClient();

  try {
    const [row] = await db.select<StoredCreativeWork>(id);
    return row || null;
  } finally {
    await db.close();
  }
}

export async function createCreativeWork(input: Omit<StoredCreativeWork, 'createdAt' | 'updatedAt'>): Promise<StoredCreativeWork> {
  const db = await createSurrealClient();
  const now = new Date().toISOString();

  try {
    const [created] = await db.create<StoredCreativeWork>('creative_work', {
      ...input,
      status: input.status || 'draft',
      createdAt: now,
      updatedAt: now,
    });

    return created;
  } finally {
    await db.close();
  }
}

export async function updateCreativeWork(id: string, input: Partial<StoredCreativeWork>): Promise<StoredCreativeWork> {
  const db = await createSurrealClient();

  try {
    const [updated] = await db.merge<StoredCreativeWork>(id, {
      ...input,
      updatedAt: new Date().toISOString(),
    });

    return updated;
  } finally {
    await db.close();
  }
}

export async function deleteCreativeWork(id: string): Promise<StoredCreativeWork | null> {
  const db = await createSurrealClient();

  try {
    const [deleted] = await db.delete<StoredCreativeWork>(id);
    return deleted || null;
  } finally {
    await db.close();
  }
}
