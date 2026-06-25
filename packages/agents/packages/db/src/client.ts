import { Surreal } from 'surrealdb';

export interface SurrealConfig {
  url?: string;
  namespace?: string;
  database?: string;
  username?: string;
  password?: string;
}

export function getSurrealConfig(env: Record<string, string | undefined> = process.env): Required<SurrealConfig> {
  return {
    url: env.SURREALDB_URL || 'http://127.0.0.1:8000/rpc',
    namespace: env.SURREALDB_NAMESPACE || 'publishing_platform',
    database: env.SURREALDB_DATABASE || 'main',
    username: env.SURREALDB_USERNAME || 'root',
    password: env.SURREALDB_PASSWORD || 'root',
  };
}

export async function createSurrealClient(config: SurrealConfig = {}): Promise<Surreal> {
  const resolved = { ...getSurrealConfig(), ...config };
  const db = new Surreal();

  await db.connect(resolved.url);
  await db.signin({
    username: resolved.username,
    password: resolved.password,
  });
  await db.use({
    namespace: resolved.namespace,
    database: resolved.database,
  });

  return db;
}

export async function closeSurrealClient(db: Surreal): Promise<void> {
  await db.close();
}
