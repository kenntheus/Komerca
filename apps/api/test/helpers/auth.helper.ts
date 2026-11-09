import request from 'supertest';
import { app } from '../../src/app';
import { prisma } from '../../src/core/prisma';

const TEST_PHONE = '+639123456789';

export async function loginTestUser(phone = TEST_PHONE): Promise<{
  accessToken: string;
  refreshToken: string;
  userId: string;
}> {
  // Request OTP
  await request(app).post('/api/v1/auth/otp/request').send({ phone }).expect(200);

  // In test env the code is always '123456'
  const res = await request(app)
    .post('/api/v1/auth/otp/verify')
    .send({ phone, code: '123456' })
    .expect(200);

  return {
    accessToken: res.body.accessToken as string,
    refreshToken: res.body.refreshToken as string,
    userId: (res.body.user as { id: string }).id,
  };
}

export function authHeader(token: string) {
  return { Authorization: `Bearer ${token}` };
}

export async function getCategory(slug = 'phones-gadgets') {
  return prisma.category.findUniqueOrThrow({ where: { slug } });
}
