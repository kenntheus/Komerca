import { prisma } from '../../src/core/prisma';
import { CATEGORIES_CONFIG } from '../../src/modules/categories/category.config';

export async function seedCategories() {
  for (const cat of CATEGORIES_CONFIG) {
    await prisma.category.upsert({
      where: { slug: cat.slug },
      create: { slug: cat.slug, name: cat.name, iconName: cat.iconName, sortOrder: cat.sortOrder },
      update: {},
    });
  }
}

export async function cleanDb() {
  await prisma.$transaction([
    prisma.message.deleteMany(),
    prisma.inquiry.deleteMany(),
    prisma.offer.deleteMany(),
    prisma.reservation.deleteMany(),
    prisma.review.deleteMany(),
    prisma.report.deleteMany(),
    prisma.listingPhoto.deleteMany(),
    prisma.listing.deleteMany(),
    prisma.otpToken.deleteMany(),
    prisma.refreshToken.deleteMany(),
    prisma.user.deleteMany(),
  ]);
}
