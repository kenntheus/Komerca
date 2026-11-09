import { Router } from 'express';
import { z } from 'zod';
import { authenticate } from '../../core/middleware/authenticate';
import { ValidationError } from '../../core/errors';
import * as usersService from './users.service';
import { UpdateMeSchema } from './users.schema';

const router = Router();

function validate<T>(schema: z.ZodType<T>, body: unknown): T {
  const result = schema.safeParse(body);
  if (!result.success) throw new ValidationError(result.error.errors[0]?.message ?? 'Validation failed');
  return result.data;
}

router.get('/me', authenticate, async (req, res, next) => {
  try {
    const user = await usersService.getUser(req.user!.id);
    res.json(user);
  } catch (err) {
    next(err);
  }
});

router.patch('/me', authenticate, async (req, res, next) => {
  try {
    const data = validate(UpdateMeSchema, req.body);
    const user = await usersService.updateMe(req.user!.id, data);
    res.json(user);
  } catch (err) {
    next(err);
  }
});

router.get('/:id', async (req, res, next) => {
  try {
    const user = await usersService.getPublicUser(req.params.id);
    res.json(user);
  } catch (err) {
    next(err);
  }
});

router.get('/:id/listings', async (req, res, next) => {
  try {
    const page = Math.max(1, parseInt(req.query.page as string) || 1);
    const limit = Math.min(50, Math.max(1, parseInt(req.query.limit as string) || 20));
    const result = await usersService.getUserListings(req.params.id, page, limit);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

export default router;
