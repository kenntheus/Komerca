import { Router } from 'express';
import { z } from 'zod';
import { authenticate } from '../../core/middleware/authenticate';
import { ValidationError } from '../../core/errors';
import * as listingsService from './listings.service';
import {
  CreateListingSchema,
  UpdateListingSchema,
  ListingsQuerySchema,
  RegisterPhotoSchema,
} from './listings.schema';

const router = Router();

function validate<T>(schema: z.ZodType<T>, data: unknown): T {
  const result = schema.safeParse(data);
  if (!result.success) throw new ValidationError(result.error.errors[0]?.message ?? 'Validation failed');
  return result.data;
}

router.get('/', async (req, res, next) => {
  try {
    const params = validate(ListingsQuerySchema, req.query);
    const listings = await listingsService.listListings(params);
    res.json(listings);
  } catch (err) {
    next(err);
  }
});

router.post('/', authenticate, async (req, res, next) => {
  try {
    const data = validate(CreateListingSchema, req.body);
    const listing = await listingsService.createListing(req.user!.id, data);
    res.status(201).json(listing);
  } catch (err) {
    next(err);
  }
});

router.get('/:id', async (req, res, next) => {
  try {
    const listing = await listingsService.getListing(req.params.id);
    res.json(listing);
  } catch (err) {
    next(err);
  }
});

router.patch('/:id', authenticate, async (req, res, next) => {
  try {
    const data = validate(UpdateListingSchema, req.body);
    const listing = await listingsService.updateListing(req.params.id, req.user!.id, req.user!.role, data);
    res.json(listing);
  } catch (err) {
    next(err);
  }
});

router.delete('/:id', authenticate, async (req, res, next) => {
  try {
    await listingsService.removeListing(req.params.id, req.user!.id, req.user!.role);
    res.json({ message: 'Listing removed' });
  } catch (err) {
    next(err);
  }
});

router.post('/:id/publish', authenticate, async (req, res, next) => {
  try {
    const listing = await listingsService.publishListing(req.params.id, req.user!.id, req.user!.role);
    res.json(listing);
  } catch (err) {
    next(err);
  }
});

router.post('/:id/sold', authenticate, async (req, res, next) => {
  try {
    const listing = await listingsService.markSold(req.params.id, req.user!.id, req.user!.role);
    res.json(listing);
  } catch (err) {
    next(err);
  }
});

// Photos
router.post('/:id/photos/sign', authenticate, async (req, res, next) => {
  try {
    const result = await listingsService.signPhoto(req.params.id, req.user!.id, req.user!.role);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

router.post('/:id/photos', authenticate, async (req, res, next) => {
  try {
    const data = validate(RegisterPhotoSchema, req.body);
    const photo = await listingsService.addPhoto(req.params.id, req.user!.id, req.user!.role, data);
    res.status(201).json(photo);
  } catch (err) {
    next(err);
  }
});

router.delete('/:id/photos/:photoId', authenticate, async (req, res, next) => {
  try {
    await listingsService.deletePhoto(req.params.id, req.params.photoId, req.user!.id, req.user!.role);
    res.json({ message: 'Photo deleted' });
  } catch (err) {
    next(err);
  }
});

export default router;
