import { z } from 'zod';

export const UpdateMeSchema = z.object({
  name: z.string().min(1).max(100).optional(),
  city: z.string().max(100).optional(),
  avatarUrl: z.string().url().optional().nullable(),
});
