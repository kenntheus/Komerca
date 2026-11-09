import { describe, it, expect, beforeAll, beforeEach, afterAll } from 'vitest';
import request from 'supertest';
import { app } from '../../src/app';
import { prisma } from '../../src/core/prisma';
import { cleanDb, seedCategories } from '../helpers/setup';
import { loginTestUser, authHeader, getCategory } from '../helpers/auth.helper';

let accessToken: string;
let userId: string;
let categoryId: string;

beforeAll(async () => {
  await seedCategories();
});

beforeEach(async () => {
  await cleanDb();
  const auth = await loginTestUser('+639200000001');
  accessToken = auth.accessToken;
  userId = auth.userId;
  const cat = await getCategory('phones-gadgets');
  categoryId = cat.id;
});

afterAll(() => prisma.$disconnect());

const validListing = () => ({
  categoryId,
  title: 'iPhone 13 Pro 256GB',
  description: 'Excellent condition, comes with original box and accessories',
  price: 32000,
  condition: 'LIKE_NEW',
  city: 'Manila',
  attributes: { brand: 'Apple', model: 'iPhone 13 Pro' },
});

describe('POST /listings', () => {
  it('creates a draft listing', async () => {
    const res = await request(app)
      .post('/api/v1/listings')
      .set(authHeader(accessToken))
      .send(validListing());
    expect(res.status).toBe(201);
    expect(res.body).toMatchObject({
      status: 'DRAFT',
      title: 'iPhone 13 Pro 256GB',
    });
  });

  it('returns 400 when attributes fail category schema', async () => {
    const res = await request(app)
      .post('/api/v1/listings')
      .set(authHeader(accessToken))
      .send({ ...validListing(), attributes: { brand: '' } }); // brand must be non-empty
    expect(res.status).toBe(400);
  });

  it('returns 401 when unauthenticated', async () => {
    const res = await request(app).post('/api/v1/listings').send(validListing());
    expect(res.status).toBe(401);
  });
});

describe('GET /listings/:id', () => {
  it('returns listing detail', async () => {
    const create = await request(app)
      .post('/api/v1/listings')
      .set(authHeader(accessToken))
      .send(validListing());
    const id = (create.body as { id: string }).id;

    const res = await request(app).get(`/api/v1/listings/${id}`);
    expect(res.status).toBe(200);
    expect(res.body.id).toBe(id);
  });

  it('returns 404 for unknown id', async () => {
    const res = await request(app).get('/api/v1/listings/nonexistent-id');
    expect(res.status).toBe(404);
  });
});

describe('PATCH /listings/:id', () => {
  it('updates a draft listing', async () => {
    const create = await request(app)
      .post('/api/v1/listings')
      .set(authHeader(accessToken))
      .send(validListing());
    const id = (create.body as { id: string }).id;

    const res = await request(app)
      .patch(`/api/v1/listings/${id}`)
      .set(authHeader(accessToken))
      .send({ title: 'Updated Title', price: 30000 });
    expect(res.status).toBe(200);
    expect(res.body.title).toBe('Updated Title');
  });

  it('returns 403 when another user tries to update', async () => {
    const create = await request(app)
      .post('/api/v1/listings')
      .set(authHeader(accessToken))
      .send(validListing());
    const id = (create.body as { id: string }).id;

    const other = await loginTestUser('+639200000002');
    const res = await request(app)
      .patch(`/api/v1/listings/${id}`)
      .set(authHeader(other.accessToken))
      .send({ title: 'Hacked Title' });
    expect(res.status).toBe(403);
  });
});

describe('POST /listings/:id/publish', () => {
  it('requires at least one photo before publishing', async () => {
    const create = await request(app)
      .post('/api/v1/listings')
      .set(authHeader(accessToken))
      .send(validListing());
    const id = (create.body as { id: string }).id;

    const res = await request(app)
      .post(`/api/v1/listings/${id}/publish`)
      .set(authHeader(accessToken));
    expect(res.status).toBe(400);
    expect(res.body.message).toMatch(/photo/i);
  });

  it('publishes the listing after adding a photo', async () => {
    const create = await request(app)
      .post('/api/v1/listings')
      .set(authHeader(accessToken))
      .send(validListing());
    const id = (create.body as { id: string }).id;

    await request(app)
      .post(`/api/v1/listings/${id}/photos`)
      .set(authHeader(accessToken))
      .send({ url: 'https://example.com/photo.jpg', publicId: 'test_pub_id', sortOrder: 0 })
      .expect(201);

    const res = await request(app)
      .post(`/api/v1/listings/${id}/publish`)
      .set(authHeader(accessToken));
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ACTIVE');
  });
});

describe('GET /listings (search and browse)', () => {
  async function publishedListing(title: string, price: number) {
    const create = await request(app)
      .post('/api/v1/listings')
      .set(authHeader(accessToken))
      .send({ ...validListing(), title, price });
    const id = (create.body as { id: string }).id;
    await request(app)
      .post(`/api/v1/listings/${id}/photos`)
      .set(authHeader(accessToken))
      .send({ url: 'https://example.com/photo.jpg', publicId: `pub_${id}`, sortOrder: 0 });
    await request(app)
      .post(`/api/v1/listings/${id}/publish`)
      .set(authHeader(accessToken));
    return id;
  }

  it('returns empty array when no active listings', async () => {
    const res = await request(app).get('/api/v1/listings');
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.length).toBe(0);
  });

  it('returns active listings sorted by newest', async () => {
    await publishedListing('Galaxy A54', 12000);
    await publishedListing('MacBook Air', 50000);

    const res = await request(app).get('/api/v1/listings?sortBy=newest');
    expect(res.status).toBe(200);
    expect((res.body as unknown[]).length).toBe(2);
  });

  it('filters by minPrice and maxPrice', async () => {
    await publishedListing('Cheap Phone', 5000);
    await publishedListing('Mid Phone', 15000);
    await publishedListing('Expensive Phone', 60000);

    const res = await request(app).get('/api/v1/listings?minPrice=10000&maxPrice=20000');
    expect(res.status).toBe(200);
    expect((res.body as unknown[]).length).toBe(1);
    expect((res.body as Array<{ title: string }>)[0].title).toBe('Mid Phone');
  });

  it('sorts by price ascending', async () => {
    await publishedListing('Expensive', 50000);
    await publishedListing('Cheap', 5000);

    const res = await request(app).get('/api/v1/listings?sortBy=price_asc');
    expect(res.status).toBe(200);
    const prices = (res.body as Array<{ price: string }>).map((l) => parseFloat(l.price));
    expect(prices[0]).toBeLessThan(prices[1]);
  });

  it('filters by categoryId', async () => {
    await publishedListing('Phone in category', 20000);

    const fashionCat = await getCategory('fashion');
    const fashionListing = await request(app)
      .post('/api/v1/listings')
      .set(authHeader(accessToken))
      .send({
        categoryId: fashionCat.id,
        title: 'Nike Shirt',
        description: 'Brand new Nike shirt in size M, comfortable fabric',
        price: 500,
        condition: 'NEW',
        city: 'Cebu',
        attributes: { size: 'M' },
      });
    const fashionId = (fashionListing.body as { id: string }).id;
    await request(app)
      .post(`/api/v1/listings/${fashionId}/photos`)
      .set(authHeader(accessToken))
      .send({ url: 'https://example.com/shirt.jpg', publicId: 'shirt_pub', sortOrder: 0 });
    await request(app)
      .post(`/api/v1/listings/${fashionId}/publish`)
      .set(authHeader(accessToken));

    const res = await request(app).get(`/api/v1/listings?categoryId=${fashionCat.id}`);
    expect(res.status).toBe(200);
    expect((res.body as unknown[]).length).toBe(1);
    expect((res.body as Array<{ title: string }>)[0].title).toBe('Nike Shirt');
  });
});

describe('DELETE /listings/:id', () => {
  it('removes listing (status becomes REMOVED)', async () => {
    const create = await request(app)
      .post('/api/v1/listings')
      .set(authHeader(accessToken))
      .send(validListing());
    const id = (create.body as { id: string }).id;

    const del = await request(app)
      .delete(`/api/v1/listings/${id}`)
      .set(authHeader(accessToken));
    expect(del.status).toBe(200);

    const get = await request(app).get(`/api/v1/listings/${id}`);
    expect(get.status).toBe(404);
  });
});
