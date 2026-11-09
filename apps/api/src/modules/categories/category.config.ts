import { z } from 'zod';

export const CATEGORY_SCHEMAS = {
  'phones-gadgets': z.object({
    brand: z.string().min(1, 'Brand is required'),
    model: z.string().min(1, 'Model is required'),
    storage: z.string().optional(),
    color: z.string().optional(),
    hasWarranty: z.boolean().optional(),
  }),
  fashion: z.object({
    size: z.string().min(1, 'Size is required'),
    brand: z.string().optional(),
    color: z.string().optional(),
    gender: z.enum(['men', 'women', 'unisex', 'kids']).optional(),
    material: z.string().optional(),
  }),
  'home-furniture': z.object({
    material: z.string().optional(),
    dimensions: z.string().optional(),
    color: z.string().optional(),
    brand: z.string().optional(),
  }),
  'books-school': z.object({
    subject: z.string().optional(),
    gradeLevel: z.string().optional(),
    author: z.string().optional(),
    edition: z.string().optional(),
    isbn: z.string().optional(),
  }),
} as const;

export type CategorySlug = keyof typeof CATEGORY_SCHEMAS;

export const CATEGORIES_CONFIG = [
  { slug: 'phones-gadgets' as const, name: 'Phones & Gadgets', iconName: 'smartphone', sortOrder: 1 },
  { slug: 'fashion' as const, name: 'Fashion', iconName: 'checkroom', sortOrder: 2 },
  { slug: 'home-furniture' as const, name: 'Home & Furniture', iconName: 'chair', sortOrder: 3 },
  { slug: 'books-school' as const, name: 'Books & School', iconName: 'menu_book', sortOrder: 4 },
];

export function getCategorySchema(slug: string) {
  return CATEGORY_SCHEMAS[slug as CategorySlug] ?? null;
}
