import jwt from 'jsonwebtoken';
import type { UserRole } from '@prisma/client';
import { getEnv } from '../config/env';

export type AccessTokenPayload = {
  sub: string;
  role: UserRole;
};

export function signAccessToken(payload: AccessTokenPayload): string {
  return jwt.sign(payload, getEnv().JWT_ACCESS_SECRET, { expiresIn: '15m' });
}

export function verifyAccessToken(token: string): AccessTokenPayload | null {
  try {
    return jwt.verify(token, getEnv().JWT_ACCESS_SECRET) as AccessTokenPayload;
  } catch {
    return null;
  }
}
