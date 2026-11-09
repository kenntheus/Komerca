import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { z } from 'zod';
import { authenticate } from '../../core/middleware/authenticate';
import { ValidationError } from '../../core/errors';
import * as authService from './auth.service';
import { RequestOtpSchema, VerifyOtpSchema, RefreshTokenSchema, LogoutSchema } from './auth.schema';

const router = Router();

const otpRequestLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 5,
  keyGenerator: (req) => (req.body?.phone as string | undefined) ?? req.ip ?? 'unknown',
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'too_many_requests', message: 'Too many OTP requests. Please wait and try again.' },
  skip: () => process.env.NODE_ENV === 'test',
});

function validate<T>(schema: z.ZodType<T>, body: unknown): T {
  const result = schema.safeParse(body);
  if (!result.success) throw new ValidationError(result.error.errors[0]?.message ?? 'Validation failed');
  return result.data;
}

router.post('/otp/request', otpRequestLimiter, async (req, res, next) => {
  try {
    const { phone } = validate(RequestOtpSchema, req.body);
    await authService.requestOtp(phone);
    res.json({ message: 'OTP sent' });
  } catch (err) {
    next(err);
  }
});

router.post('/otp/verify', async (req, res, next) => {
  try {
    const { phone, code } = validate(VerifyOtpSchema, req.body);
    const result = await authService.verifyOtp(phone, code);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

router.post('/token/refresh', async (req, res, next) => {
  try {
    const { refreshToken } = validate(RefreshTokenSchema, req.body);
    const result = await authService.refreshTokens(refreshToken);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

router.post('/logout', authenticate, async (req, res, next) => {
  try {
    const { refreshToken } = validate(LogoutSchema, req.body);
    await authService.logout(refreshToken);
    res.json({ message: 'Logged out' });
  } catch (err) {
    next(err);
  }
});

export default router;
