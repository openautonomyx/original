import type { APIRoute } from 'astro';
import {
  createCreativeWork,
  listCreativeWorks,
} from '@publishing-platform/db';

export const GET: APIRoute = async ({ url }) => {
  const tenant = url.searchParams.get('tenant') || undefined;
  const works = await listCreativeWorks(tenant);

  return new Response(JSON.stringify(works), {
    status: 200,
    headers: {
      'content-type': 'application/json',
    },
  });
};

export const POST: APIRoute = async ({ request }) => {
  const payload = await request.json();
  const created = await createCreativeWork(payload);

  return new Response(JSON.stringify(created), {
    status: 201,
    headers: {
      'content-type': 'application/json',
    },
  });
};
