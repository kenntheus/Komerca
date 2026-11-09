import express from 'express';
import { errorHandler } from './core/middleware/errorHandler';
import { requestLogger } from './core/middleware/logger';
import authRouter from './modules/auth/auth.router';
import usersRouter from './modules/users/users.router';
import categoriesRouter from './modules/categories/categories.router';
import listingsRouter from './modules/listings/listings.router';

export const app = express();

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(requestLogger);

app.get('/api/v1/health', (_req, res) => {
  res.json({ status: 'ok' });
});

app.use('/api/v1/auth', authRouter);
app.use('/api/v1/users', usersRouter);
app.use('/api/v1/categories', categoriesRouter);
app.use('/api/v1/listings', listingsRouter);

app.use((_req, res) => {
  res.status(404).json({ error: 'not_found' });
});

app.use(errorHandler);
