import {
  createCreativeWorkRecord,
  listCreativeWorkRecords
} from '@publishing-platform/db';

export async function GET({ url }) {
  const tenant = url.searchParams.get('tenant');
  const status = url.searchParams.get('status');
  const creativeWorkType = url.searchParams.get('creativeWorkType');

  const records = await listCreativeWorkRecords({
    tenant,
    status,
    creativeWorkType
  });

  return new Response(JSON.stringify(records), {
    status: 200,
    headers: {
      'content-type': 'application/json'
    }
  });
}

export async function POST({ request }) {
  const payload = await request.json();

  const created = await createCreativeWorkRecord(payload);

  return new Response(JSON.stringify(created), {
    status: 201,
    headers: {
      'content-type': 'application/json'
    }
  });
}
