import type { NextFunction, Request, Response } from 'express';
import { ZodError } from 'zod';
import { AppError } from '../errors';

export function errorHandler(
  err: unknown,
  _req: Request,
  res: Response,
  _next: NextFunction,
): void {
  if (err instanceof AppError) {
    res.status(err.statusCode).json({ error: err.code, message: err.message });
    return;
  }

  if (err instanceof ZodError) {
    res.status(400).json({ error: 'validation_error', details: err.flatten() });
    return;
  }

  console.error('[unhandled error]', err);
  res.status(500).json({ error: 'internal_error', message: 'An unexpected error occurred' });
}
