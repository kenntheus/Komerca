import express from 'express';
import { errorHandler } from './core/middleware/errorHandler';
import { requestLogger } from './core/middleware/logger';

export const app = express();

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(requestLogger);

app.get('/api/v1/health', (_req, res) => {
  res.json({ status: 'ok' });
});

app.use((_req, res) => {
  res.status(404).json({ error: 'not_found' });
});

app.use(errorHandler);
