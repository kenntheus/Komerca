import { Router } from 'express';
import { prisma } from '../../core/prisma';
import { NotFoundError } from '../../core/errors';
import { getCategorySchema, CATEGORY_SCHEMAS } from './category.config';

const router = Router();

router.get('/', async (_req, res, next) => {
  try {
    const categories = await prisma.category.findMany({ orderBy: { sortOrder: 'asc' } });
    res.json(categories);
  } catch (err) {
    next(err);
  }
});

router.get('/:slug', async (req, res, next) => {
  try {
    const category = await prisma.category.findUnique({ where: { slug: req.params.slug } });
    if (!category) throw new NotFoundError('Category not found');

    const schema = getCategorySchema(category.slug);
    const attributeSchema = schema ? schema._def : null;

    // Serialize the Zod schema shape as simple field descriptors for the client
    const fields =
      schema && schema.shape
        ? Object.entries(schema.shape).map(([key, field]) => ({
            key,
            required: !field.isOptional(),
            type: (field._def as { typeName?: string }).typeName ?? 'string',
          }))
        : [];

    res.json({ ...category, attributeFields: fields });
  } catch (err) {
    next(err);
  }
});

// Expose the raw Zod schema shape keys for internal use (used in listings validation)
export { CATEGORY_SCHEMAS };

export default router;
