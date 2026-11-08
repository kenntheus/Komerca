import { describe, expect, it } from 'vitest';
import supertest from 'supertest';
import { app } from '../helpers/app';

describe('GET /api/v1/health', () => {
  it('returns 200 with { status: "ok" }', async () => {
    const res = await supertest(app).get('/api/v1/health');
    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({ status: 'ok' });
  });

  it('unknown routes return 404', async () => {
    const res = await supertest(app).get('/api/v1/unknown-route');
    expect(res.status).toBe(404);
    expect(res.body).toMatchObject({ error: 'not_found' });
  });
});
