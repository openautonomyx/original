import {
  createMembership,
  createSession,
  createTenant,
  createUser
} from '@publishing-platform/db';

export async function POST({ request }) {
  const body = await request.json();
  const tenant = await createTenant({
    name: body.tenantName || 'Default Workspace',
    slug: body.tenantSlug || `workspace-${Date.now()}`
  });
  const user = await createUser({
    email: body.email || `user-${Date.now()}@example.com`,
    name: body.name || 'Editor'
  });
  const membership = await createMembership({
    user: user.id,
    tenant: tenant.id,
    role: body.role || 'owner'
  });
  const session = await createSession({
    user: user.id
  });

  return new Response(JSON.stringify({ tenant, user, membership, session }), {
    status: 201,
    headers: { 'content-type': 'application/json' }
  });
}
