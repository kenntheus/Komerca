import { z } from 'zod';
import dotenv from 'dotenv';

dotenv.config();

const schema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().default(3000),
  DATABASE_URL: z.string().min(1),
  JWT_ACCESS_SECRET: z.string().min(32),
  JWT_REFRESH_SECRET: z.string().min(32),
  IMAGE_STORAGE: z.enum(['cloudinary', 'local']).default('local'),
  CLOUDINARY_CLOUD_NAME: z.string().optional(),
  CLOUDINARY_API_KEY: z.string().optional(),
  CLOUDINARY_API_SECRET: z.string().optional(),
  SMS_PROVIDER: z.enum(['mock', 'semaphore']).default('mock'),
  SEMAPHORE_API_KEY: z.string().optional(),
  AI_PROVIDER: z.enum(['mock', 'claude']).default('mock'),
  AI_API_KEY: z.string().optional(),
  AI_MODEL: z.string().default('claude-haiku-4-5-20251001'),
});

export type Env = z.infer<typeof schema>;

let _env: Env | undefined;

export function getEnv(): Env {
  if (_env) return _env;
  const result = schema.safeParse(process.env);
  if (!result.success) {
    const errors = JSON.stringify(result.error.flatten().fieldErrors, null, 2);
    throw new Error(`Invalid environment variables:\n${errors}`);
  }
  _env = result.data;
  return _env;
}
