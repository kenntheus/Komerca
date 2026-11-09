import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  const categories = [
    { slug: 'phones-gadgets', name: 'Phones & Gadgets', iconName: 'smartphone', sortOrder: 1 },
    { slug: 'fashion', name: 'Fashion', iconName: 'checkroom', sortOrder: 2 },
    { slug: 'home-furniture', name: 'Home & Furniture', iconName: 'chair', sortOrder: 3 },
    { slug: 'books-school', name: 'Books & School', iconName: 'menu_book', sortOrder: 4 },
  ];

  for (const cat of categories) {
    await prisma.category.upsert({
      where: { slug: cat.slug },
      create: cat,
      update: { name: cat.name, iconName: cat.iconName, sortOrder: cat.sortOrder },
    });
  }

  // Sample reference prices for listing-check feature (not real market prices)
  const refPrices = [
    { model: 'iPhone 13', minPrice: 25000, maxPrice: 40000 },
    { model: 'iPhone 14', minPrice: 35000, maxPrice: 50000 },
    { model: 'iPhone 15', minPrice: 45000, maxPrice: 65000 },
    { model: 'Samsung Galaxy A54', minPrice: 10000, maxPrice: 18000 },
    { model: 'Samsung Galaxy S23', minPrice: 25000, maxPrice: 45000 },
    { model: 'MacBook Air M1', minPrice: 45000, maxPrice: 70000 },
    { model: 'iPad 10th Gen', minPrice: 20000, maxPrice: 35000 },
    { model: 'AirPods Pro', minPrice: 8000, maxPrice: 14000 },
  ];

  for (const rp of refPrices) {
    await prisma.referencePrice.upsert({
      where: { model: rp.model },
      create: { model: rp.model, minPrice: rp.minPrice, maxPrice: rp.maxPrice },
      update: { minPrice: rp.minPrice, maxPrice: rp.maxPrice },
    });
  }

  console.log('Seed complete: 4 categories, 8 reference prices');
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
