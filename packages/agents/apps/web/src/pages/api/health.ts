import type { APIRoute } from 'astro';

export const GET: APIRoute = () => {
  return new Response(
    JSON.stringify({
      status: 'ok',
      service: 'publishing-platform-web'
    }),
    {
      status: 200,
      headers: {
        'content-type': 'application/json'
      }
    }
  );
};
