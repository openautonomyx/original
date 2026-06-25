import {
  getCreativeWorkRecord,
  updateCreativeWorkRecord
} from '@publishing-platform/db';

export async function GET({ params }) {
  const record = await getCreativeWorkRecord(params.id);

  if (!record) {
    return new Response(JSON.stringify({ error: 'Content not found' }), {
      status: 404,
      headers: { 'content-type': 'application/json' }
    });
  }

  return new Response(JSON.stringify(record), {
    status: 200,
    headers: { 'content-type': 'application/json' }
  });
}

export async function PATCH({ params, request }) {
  const payload = await request.json();
  const updated = await updateCreativeWorkRecord(params.id, payload);

  return new Response(JSON.stringify(updated), {
    status: 200,
    headers: { 'content-type': 'application/json' }
  });
}
