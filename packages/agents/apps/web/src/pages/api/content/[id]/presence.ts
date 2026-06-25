import {
  listContentPresence,
  upsertContentPresence
} from '@publishing-platform/db';

export async function GET({ params }) {
  const presence = await listContentPresence(params.id);

  return new Response(JSON.stringify(presence), {
    status: 200,
    headers: { 'content-type': 'application/json' }
  });
}

export async function POST({ params, request }) {
  const payload = await request.json();

  const presence = await upsertContentPresence({
    workId: params.id,
    userId: payload.userId || 'anonymous',
    name: payload.name || 'Anonymous collaborator',
    cursor: payload.cursor || null,
    status: payload.status || 'editing'
  });

  return new Response(JSON.stringify(presence), {
    status: 200,
    headers: { 'content-type': 'application/json' }
  });
}
