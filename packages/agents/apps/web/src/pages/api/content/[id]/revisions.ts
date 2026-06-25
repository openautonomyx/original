import { listContentRevisions } from '@publishing-platform/db';

export async function GET({ params }) {
  const revisions = await listContentRevisions(params.id);

  return new Response(JSON.stringify(revisions), {
    status: 200,
    headers: { 'content-type': 'application/json' }
  });
}
