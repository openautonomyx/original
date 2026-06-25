import { transitionCreativeWorkRecord } from '@publishing-platform/db';

export async function POST({ params, request }) {
  const body = await request.json();

  const updated = await transitionCreativeWorkRecord(
    params.id,
    body.status,
    body.actor
  );

  return new Response(JSON.stringify(updated), {
    status: 200,
    headers: {
      'content-type': 'application/json'
    }
  });
}
