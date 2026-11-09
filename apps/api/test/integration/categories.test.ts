import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import { app } from '../../src/app';
import { prisma } from '../../src/core/prisma';
import { seedCategories } from '../helpers/setup';

beforeAll(() => seedCategories());
afterAll(() => prisma.$disconnect());

describe('GET /categories', () => {
  it('returns all 4 categories sorted by sortOrder', async () => {
    const res = await request(app).get('/api/v1/categories');
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.length).toBeGreaterThanOrEqual(4);
    const slugs = (res.body as Array<{ slug: string }>).map((c) => c.slug);
    expect(slugs).toContain('phones-gadgets');
    expect(slugs).toContain('fashion');
    expect(slugs).toContain('home-furniture');
    expect(slugs).toContain('books-school');
  });
});

describe('GET /categories/:slug', () => {
  it('returns category with attribute fields', async () => {
    const res = await request(app).get('/api/v1/categories/phones-gadgets');
    expect(res.status).toBe(200);
    expect(res.body.slug).toBe('phones-gadgets');
    expect(Array.isArray(res.body.attributeFields)).toBe(true);
    const fieldKeys = (res.body.attributeFields as Array<{ key: string }>).map((f) => f.key);
    expect(fieldKeys).toContain('brand');
    expect(fieldKeys).toContain('model');
  });

  it('returns 404 for unknown slug', async () => {
    const res = await request(app).get('/api/v1/categories/unknown-category');
    expect(res.status).toBe(404);
  });
});
