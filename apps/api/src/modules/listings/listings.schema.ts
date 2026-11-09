import { z } from 'zod';
import { ListingCondition } from '@prisma/client';

export const CreateListingSchema = z.object({
  categoryId: z.string().min(1, 'Category is required'),
  title: z.string().min(3, 'Title must be at least 3 characters').max(200),
  description: z.string().min(10, 'Description must be at least 10 characters').max(2000),
  price: z.number().positive('Price must be positive').max(9_999_999.99),
  condition: z.nativeEnum(ListingCondition),
  city: z.string().min(1, 'City is required').max(100),
  lat: z.number().min(-90).max(90).optional(),
  lng: z.number().min(-180).max(180).optional(),
  attributes: z.record(z.unknown()).default({}),
});

export const UpdateListingSchema = z.object({
  title: z.string().min(3).max(200).optional(),
  description: z.string().min(10).max(2000).optional(),
  price: z.number().positive().max(9_999_999.99).optional(),
  condition: z.nativeEnum(ListingCondition).optional(),
  city: z.string().min(1).max(100).optional(),
  lat: z.number().min(-90).max(90).optional().nullable(),
  lng: z.number().min(-180).max(180).optional().nullable(),
  attributes: z.record(z.unknown()).optional(),
});

export const ListingsQuerySchema = z.object({
  q: z.string().optional(),
  categoryId: z.string().optional(),
  city: z.string().optional(),
  minPrice: z.coerce.number().optional(),
  maxPrice: z.coerce.number().optional(),
  condition: z.nativeEnum(ListingCondition).optional(),
  sortBy: z.enum(['newest', 'price_asc', 'price_desc', 'nearest']).default('newest'),
  lat: z.coerce.number().optional(),
  lng: z.coerce.number().optional(),
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(50).default(20),
});

export const RegisterPhotoSchema = z.object({
  url: z.string().url('URL must be valid'),
  publicId: z.string().min(1, 'publicId is required'),
  sortOrder: z.number().int().min(0).default(0),
});

export type CreateListingInput = z.infer<typeof CreateListingSchema>;
export type UpdateListingInput = z.infer<typeof UpdateListingSchema>;
export type ListingsQuery = z.infer<typeof ListingsQuerySchema>;
