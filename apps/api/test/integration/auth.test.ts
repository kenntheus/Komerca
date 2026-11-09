import { describe, it, expect, beforeAll, beforeEach, afterAll } from 'vitest';
import request from 'supertest';
import { app } from '../../src/app';
import { prisma } from '../../src/core/prisma';
import { cleanDb } from '../helpers/setup';

const PHONE = '+639100000001';

beforeEach(() => cleanDb());
afterAll(() => prisma.$disconnect());

describe('POST /auth/otp/request', () => {
  it('returns 200 and sends OTP', async () => {
    const res = await request(app).post('/api/v1/auth/otp/request').send({ phone: PHONE });
    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({ message: 'OTP sent' });
  });

  it('returns 400 for invalid phone format', async () => {
    const res = await request(app).post('/api/v1/auth/otp/request').send({ phone: '09123456789' });
    expect(res.status).toBe(400);
    expect(res.body.error).toBe('validation_error');
  });
});

describe('POST /auth/otp/verify', () => {
  beforeEach(async () => {
    await request(app).post('/api/v1/auth/otp/request').send({ phone: PHONE });
  });

  it('issues access and refresh tokens on valid code', async () => {
    const res = await request(app).post('/api/v1/auth/otp/verify').send({ phone: PHONE, code: '123456' });
    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({
      accessToken: expect.any(String),
      refreshToken: expect.any(String),
      user: { phone: PHONE },
    });
  });

  it('returns 401 for wrong code', async () => {
    const res = await request(app).post('/api/v1/auth/otp/verify').send({ phone: PHONE, code: '000000' });
    expect(res.status).toBe(401);
  });

  it('returns 400 for code shorter than 6 digits', async () => {
    const res = await request(app).post('/api/v1/auth/otp/verify').send({ phone: PHONE, code: '123' });
    expect(res.status).toBe(400);
  });
});

describe('POST /auth/token/refresh', () => {
  it('rotates the refresh token', async () => {
    await request(app).post('/api/v1/auth/otp/request').send({ phone: PHONE });
    const login = await request(app)
      .post('/api/v1/auth/otp/verify')
      .send({ phone: PHONE, code: '123456' });
    const { refreshToken } = login.body as { refreshToken: string };

    const res = await request(app).post('/api/v1/auth/token/refresh').send({ refreshToken });
    expect(res.status).toBe(200);
    expect(res.body.accessToken).toBeTruthy();
    expect(res.body.refreshToken).toBeTruthy();
    expect(res.body.refreshToken).not.toBe(refreshToken);
  });

  it('returns 401 for invalid refresh token', async () => {
    const res = await request(app)
      .post('/api/v1/auth/token/refresh')
      .send({ refreshToken: 'invalid-token' });
    expect(res.status).toBe(401);
  });
});

describe('GET /users/me', () => {
  it('returns user profile when authenticated', async () => {
    await request(app).post('/api/v1/auth/otp/request').send({ phone: PHONE });
    const login = await request(app)
      .post('/api/v1/auth/otp/verify')
      .send({ phone: PHONE, code: '123456' });
    const { accessToken } = login.body as { accessToken: string };

    const res = await request(app)
      .get('/api/v1/users/me')
      .set('Authorization', `Bearer ${accessToken}`);
    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({ phone: PHONE });
  });

  it('returns 401 without token', async () => {
    const res = await request(app).get('/api/v1/users/me');
    expect(res.status).toBe(401);
  });
});

describe('POST /auth/logout', () => {
  it('invalidates the refresh token', async () => {
    await request(app).post('/api/v1/auth/otp/request').send({ phone: PHONE });
    const login = await request(app)
      .post('/api/v1/auth/otp/verify')
      .send({ phone: PHONE, code: '123456' });
    const { accessToken, refreshToken } = login.body as { accessToken: string; refreshToken: string };

    const logout = await request(app)
      .post('/api/v1/auth/logout')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({ refreshToken });
    expect(logout.status).toBe(200);

    // Using the same refresh token now returns 401
    const refresh = await request(app)
      .post('/api/v1/auth/token/refresh')
      .send({ refreshToken });
    expect(refresh.status).toBe(401);
  });
});
