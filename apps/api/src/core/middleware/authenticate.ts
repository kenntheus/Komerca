import type { Request, Response, NextFunction } from 'express';
import { verifyAccessToken } from '../../lib/jwt';
import { UnauthorizedError } from '../errors';

export function authenticate(req: Request, _res: Response, next: NextFunction): void {
  const auth = req.headers.authorization;
  if (!auth?.startsWith('Bearer ')) {
    next(new UnauthorizedError('Missing token'));
    return;
  }
  const token = auth.slice(7);
  const payload = verifyAccessToken(token);
  if (!payload) {
    next(new UnauthorizedError('Invalid or expired token'));
    return;
  }
  req.user = { id: payload.sub, role: payload.role };
  next();
}
