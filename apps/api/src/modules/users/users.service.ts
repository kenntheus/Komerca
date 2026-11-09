import { prisma } from '../../core/prisma';
import { NotFoundError } from '../../core/errors';

export async function getUser(id: string) {
  const user = await prisma.user.findUnique({
    where: { id },
    select: {
      id: true,
      phone: true,
      name: true,
      avatarUrl: true,
      city: true,
      role: true,
      completedDealCount: true,
      responseRate: true,
      createdAt: true,
    },
  });
  if (!user) throw new NotFoundError('User not found');
  return user;
}

export async function getPublicUser(id: string) {
  const user = await prisma.user.findUnique({
    where: { id },
    select: {
      id: true,
      name: true,
      avatarUrl: true,
      city: true,
      completedDealCount: true,
      responseRate: true,
      createdAt: true,
    },
  });
  if (!user) throw new NotFoundError('User not found');
  return user;
}

export async function updateMe(
  id: string,
  data: { name?: string; city?: string; avatarUrl?: string | null },
) {
  return prisma.user.update({
    where: { id },
    data: { ...data, updatedAt: new Date() },
    select: {
      id: true,
      phone: true,
      name: true,
      avatarUrl: true,
      city: true,
      role: true,
      completedDealCount: true,
      responseRate: true,
      createdAt: true,
    },
  });
}

export async function getUserListings(userId: string, page: number, limit: number) {
  const [listings, total] = await Promise.all([
    prisma.listing.findMany({
      where: { sellerId: userId, status: { not: 'REMOVED' } },
      orderBy: { createdAt: 'desc' },
      skip: (page - 1) * limit,
      take: limit,
      include: {
        photos: { orderBy: { sortOrder: 'asc' }, take: 1 },
        category: { select: { id: true, slug: true, name: true } },
      },
    }),
    prisma.listing.count({ where: { sellerId: userId, status: { not: 'REMOVED' } } }),
  ]);
  return { listings, total, page, limit };
}
