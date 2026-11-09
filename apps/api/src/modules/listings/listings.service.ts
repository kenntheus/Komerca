import { Prisma, type UserRole } from '@prisma/client';
import { prisma } from '../../core/prisma';
import { ForbiddenError, NotFoundError, ValidationError } from '../../core/errors';
import { getCategorySchema } from '../categories/category.config';
import { getImageAdapter } from '../images/index';
import type { CreateListingInput, UpdateListingInput, ListingsQuery } from './listings.schema';

const MAX_PHOTOS = 10;

function assertOwner(listing: { sellerId: string }, userId: string, role: UserRole) {
  if (listing.sellerId !== userId && role !== 'ADMIN') {
    throw new ForbiddenError('You do not own this listing');
  }
}

async function validateAttributes(categoryId: string, attributes: Record<string, unknown>) {
  const category = await prisma.category.findUnique({ where: { id: categoryId } });
  if (!category) throw new NotFoundError('Category not found');

  const schema = getCategorySchema(category.slug);
  if (!schema) return;

  const result = schema.safeParse(attributes);
  if (!result.success) {
    throw new ValidationError(result.error.errors[0]?.message ?? 'Invalid attributes');
  }
}

export async function createListing(sellerId: string, data: CreateListingInput) {
  await validateAttributes(data.categoryId, data.attributes as Record<string, unknown>);

  return prisma.listing.create({
    data: {
      sellerId,
      categoryId: data.categoryId,
      title: data.title,
      description: data.description,
      price: data.price,
      condition: data.condition,
      city: data.city,
      lat: data.lat,
      lng: data.lng,
      attributes: data.attributes,
      updatedAt: new Date(),
    },
    include: {
      category: { select: { id: true, slug: true, name: true } },
      photos: { orderBy: { sortOrder: 'asc' } },
    },
  });
}

export async function getListing(id: string) {
  const listing = await prisma.listing.findUnique({
    where: { id },
    include: {
      photos: { orderBy: { sortOrder: 'asc' } },
      seller: {
        select: { id: true, name: true, avatarUrl: true, completedDealCount: true, responseRate: true },
      },
      category: { select: { id: true, slug: true, name: true, iconName: true } },
    },
  });
  if (!listing || listing.status === 'REMOVED') throw new NotFoundError('Listing not found');

  // Increment view count without blocking the response
  void prisma.listing
    .update({ where: { id }, data: { viewCount: { increment: 1 }, updatedAt: new Date() } })
    .catch(() => undefined);

  return listing;
}

type RawListingRow = {
  id: string;
  title: string;
  price: string;
  condition: string;
  city: string;
  status: string;
  createdAt: Date;
  viewCount: number;
  lat: number | null;
  lng: number | null;
  checkLevel: string | null;
  firstPhotoUrl: string | null;
  sellerId: string;
  sellerName: string;
  sellerAvatarUrl: string | null;
  categoryId: string;
  categorySlug: string;
  categoryName: string;
};

function mapRawRow(row: RawListingRow) {
  return {
    id: row.id,
    title: row.title,
    price: row.price,
    condition: row.condition,
    city: row.city,
    status: row.status,
    createdAt: row.createdAt,
    viewCount: row.viewCount,
    lat: row.lat,
    lng: row.lng,
    checkLevel: row.checkLevel,
    photos: row.firstPhotoUrl ? [{ url: row.firstPhotoUrl }] : [],
    seller: { id: row.sellerId, name: row.sellerName, avatarUrl: row.sellerAvatarUrl },
    category: { id: row.categoryId, slug: row.categorySlug, name: row.categoryName },
  };
}

const BASE_JOIN = Prisma.sql`
  FROM "Listing" l
  LEFT JOIN LATERAL (
    SELECT url FROM "ListingPhoto"
    WHERE "listingId" = l.id
    ORDER BY "sortOrder" ASC
    LIMIT 1
  ) p ON true
  JOIN "User" u ON u.id = l."sellerId"
  JOIN "Category" c ON c.id = l."categoryId"
`;

const BASE_SELECT = Prisma.sql`
  SELECT
    l.id, l.title, l.price::text, l.condition, l.city, l.status,
    l."createdAt", l."viewCount", l.lat, l.lng, l."checkLevel",
    p.url AS "firstPhotoUrl",
    u.id AS "sellerId", u.name AS "sellerName", u."avatarUrl" AS "sellerAvatarUrl",
    c.id AS "categoryId", c.slug AS "categorySlug", c.name AS "categoryName"
`;

export async function listListings(params: ListingsQuery) {
  const offset = (params.page - 1) * params.limit;
  const conditions: Prisma.Sql[] = [Prisma.sql`l.status = 'ACTIVE'`];

  if (params.categoryId) {
    conditions.push(Prisma.sql`l."categoryId" = ${params.categoryId}`);
  }
  if (params.city) {
    conditions.push(Prisma.sql`lower(l.city) LIKE ${`%${params.city.toLowerCase()}%`}`);
  }
  if (params.minPrice !== undefined) {
    conditions.push(Prisma.sql`l.price >= ${params.minPrice}`);
  }
  if (params.maxPrice !== undefined) {
    conditions.push(Prisma.sql`l.price <= ${params.maxPrice}`);
  }
  if (params.condition) {
    conditions.push(Prisma.sql`l.condition = ${params.condition}::"ListingCondition"`);
  }
  if (params.q) {
    conditions.push(Prisma.sql`(
      l."searchVector" @@ plainto_tsquery('english', ${params.q})
      OR l.title % ${params.q}
    )`);
  }

  const whereClause =
    conditions.length > 0
      ? Prisma.sql`WHERE ${Prisma.join(conditions, ' AND ')}`
      : Prisma.empty;

  let orderClause: Prisma.Sql;
  if (params.q) {
    orderClause = Prisma.sql`ORDER BY ts_rank(l."searchVector", plainto_tsquery('english', ${params.q})) DESC, l."createdAt" DESC`;
  } else if (params.sortBy === 'price_asc') {
    orderClause = Prisma.sql`ORDER BY l.price ASC, l."createdAt" DESC`;
  } else if (params.sortBy === 'price_desc') {
    orderClause = Prisma.sql`ORDER BY l.price DESC, l."createdAt" DESC`;
  } else if (
    params.sortBy === 'nearest' &&
    params.lat !== undefined &&
    params.lng !== undefined
  ) {
    const lat = params.lat;
    const lng = params.lng;
    orderClause = Prisma.sql`ORDER BY (
      6371 * 2 * ASIN(SQRT(
        POWER(SIN(RADIANS((COALESCE(l.lat, ${lat}) - ${lat}) / 2)), 2) +
        COS(RADIANS(${lat})) * COS(RADIANS(COALESCE(l.lat, ${lat}))) *
        POWER(SIN(RADIANS((COALESCE(l.lng, ${lng}) - ${lng}) / 2)), 2)
      ))
    ) ASC, l."createdAt" DESC`;
  } else {
    orderClause = Prisma.sql`ORDER BY l."createdAt" DESC`;
  }

  const rows = await prisma.$queryRaw<RawListingRow[]>(
    Prisma.sql`${BASE_SELECT} ${BASE_JOIN} ${whereClause} ${orderClause} LIMIT ${params.limit} OFFSET ${offset}`,
  );

  return rows.map(mapRawRow);
}

export async function updateListing(id: string, userId: string, role: UserRole, data: UpdateListingInput) {
  const listing = await prisma.listing.findUnique({ where: { id } });
  if (!listing || listing.status === 'REMOVED') throw new NotFoundError('Listing not found');
  assertOwner(listing, userId, role);

  if (listing.status !== 'DRAFT' && listing.status !== 'ACTIVE') {
    throw new ValidationError('Only DRAFT or ACTIVE listings can be updated');
  }

  if (data.attributes && Object.keys(data.attributes).length > 0) {
    const merged = { ...(listing.attributes as Record<string, unknown>), ...data.attributes };
    await validateAttributes(listing.categoryId, merged);
  }

  return prisma.listing.update({
    where: { id },
    data: { ...data, updatedAt: new Date() },
    include: {
      photos: { orderBy: { sortOrder: 'asc' } },
      category: { select: { id: true, slug: true, name: true } },
    },
  });
}

export async function publishListing(id: string, userId: string, role: UserRole) {
  const listing = await prisma.listing.findUnique({
    where: { id },
    include: { photos: { take: 1 } },
  });
  if (!listing || listing.status === 'REMOVED') throw new NotFoundError('Listing not found');
  assertOwner(listing, userId, role);

  if (listing.status !== 'DRAFT') throw new ValidationError('Only DRAFT listings can be published');
  if (listing.photos.length === 0) throw new ValidationError('Add at least one photo before publishing');

  return prisma.listing.update({
    where: { id },
    data: { status: 'ACTIVE', updatedAt: new Date() },
    include: { photos: { orderBy: { sortOrder: 'asc' } } },
  });
}

export async function markSold(id: string, userId: string, role: UserRole) {
  const listing = await prisma.listing.findUnique({ where: { id } });
  if (!listing || listing.status === 'REMOVED') throw new NotFoundError('Listing not found');
  assertOwner(listing, userId, role);

  if (listing.status === 'SOLD') throw new ValidationError('Listing is already sold');
  if (listing.status === 'DRAFT') throw new ValidationError('Cannot mark a draft as sold');

  return prisma.listing.update({
    where: { id },
    data: { status: 'SOLD', updatedAt: new Date() },
  });
}

export async function removeListing(id: string, userId: string, role: UserRole) {
  const listing = await prisma.listing.findUnique({ where: { id } });
  if (!listing || listing.status === 'REMOVED') throw new NotFoundError('Listing not found');
  assertOwner(listing, userId, role);

  return prisma.listing.update({
    where: { id },
    data: { status: 'REMOVED', updatedAt: new Date() },
  });
}

export async function signPhoto(listingId: string, userId: string, role: UserRole) {
  const listing = await prisma.listing.findUnique({ where: { id: listingId } });
  if (!listing || listing.status === 'REMOVED') throw new NotFoundError('Listing not found');
  assertOwner(listing, userId, role);

  return getImageAdapter().signUpload(listingId);
}

export async function addPhoto(
  listingId: string,
  userId: string,
  role: UserRole,
  photoData: { url: string; publicId: string; sortOrder: number },
) {
  const listing = await prisma.listing.findUnique({
    where: { id: listingId },
    include: { photos: true },
  });
  if (!listing || listing.status === 'REMOVED') throw new NotFoundError('Listing not found');
  assertOwner(listing, userId, role);

  if (listing.photos.length >= MAX_PHOTOS) {
    throw new ValidationError(`Maximum ${MAX_PHOTOS} photos allowed`);
  }

  return prisma.listingPhoto.create({
    data: {
      listingId,
      url: photoData.url,
      publicId: photoData.publicId,
      sortOrder: photoData.sortOrder,
    },
  });
}

export async function deletePhoto(
  listingId: string,
  photoId: string,
  userId: string,
  role: UserRole,
) {
  const listing = await prisma.listing.findUnique({ where: { id: listingId } });
  if (!listing || listing.status === 'REMOVED') throw new NotFoundError('Listing not found');
  assertOwner(listing, userId, role);

  const photo = await prisma.listingPhoto.findFirst({ where: { id: photoId, listingId } });
  if (!photo) throw new NotFoundError('Photo not found');

  await getImageAdapter().deletePhoto(photo.publicId);
  await prisma.listingPhoto.delete({ where: { id: photoId } });
}
