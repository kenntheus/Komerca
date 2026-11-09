import { randomBytes } from 'crypto';
import { prisma } from '../../core/prisma';
import { signAccessToken } from '../../lib/jwt';
import { getSmsProvider } from '../../lib/sms';
import { ConflictError, NotFoundError, UnauthorizedError } from '../../core/errors';
import { getEnv } from '../../config/env';

const OTP_TTL_MS = 10 * 60 * 1000; // 10 minutes
const REFRESH_TOKEN_TTL_DAYS = 30;

function generateOtpCode(): string {
  const num = parseInt(randomBytes(3).toString('hex'), 16) % 900000 + 100000;
  return num.toString().padStart(6, '0');
}

function generateRefreshTokenValue(): string {
  return randomBytes(32).toString('hex');
}

export async function requestOtp(phone: string): Promise<void> {
  const now = new Date();
  const env = getEnv();

  let user = await prisma.user.findUnique({ where: { phone } });
  if (!user) {
    user = await prisma.user.create({
      data: {
        phone,
        name: 'User',
        updatedAt: now,
      },
    });
  }

  // Invalidate any existing unused, unexpired OTPs for this user
  await prisma.otpToken.updateMany({
    where: { userId: user.id, used: false, expiresAt: { gt: now } },
    data: { used: true },
  });

  const code = env.NODE_ENV === 'test' ? '123456' : generateOtpCode();
  await prisma.otpToken.create({
    data: {
      userId: user.id,
      code,
      expiresAt: new Date(now.getTime() + OTP_TTL_MS),
    },
  });

  await getSmsProvider().sendOtp(phone, code);
}

export async function verifyOtp(
  phone: string,
  code: string,
): Promise<{ accessToken: string; refreshToken: string; user: object }> {
  const now = new Date();

  const user = await prisma.user.findUnique({ where: { phone } });
  if (!user) throw new NotFoundError('User not found');

  const otp = await prisma.otpToken.findFirst({
    where: {
      userId: user.id,
      code,
      used: false,
      expiresAt: { gt: now },
    },
    orderBy: { createdAt: 'desc' },
  });

  if (!otp) throw new UnauthorizedError('Invalid or expired OTP code');

  await prisma.otpToken.update({ where: { id: otp.id }, data: { used: true } });

  const refreshTokenValue = generateRefreshTokenValue();
  const expiresAt = new Date(now.getTime() + REFRESH_TOKEN_TTL_DAYS * 24 * 60 * 60 * 1000);

  await prisma.refreshToken.create({
    data: { userId: user.id, token: refreshTokenValue, expiresAt },
  });

  const accessToken = signAccessToken({ sub: user.id, role: user.role });

  return {
    accessToken,
    refreshToken: refreshTokenValue,
    user: {
      id: user.id,
      phone: user.phone,
      name: user.name,
      avatarUrl: user.avatarUrl,
      city: user.city,
      role: user.role,
      completedDealCount: user.completedDealCount,
    },
  };
}

export async function refreshTokens(
  tokenValue: string,
): Promise<{ accessToken: string; refreshToken: string }> {
  const now = new Date();

  const stored = await prisma.refreshToken.findUnique({ where: { token: tokenValue } });
  if (!stored || stored.expiresAt < now) {
    throw new UnauthorizedError('Refresh token is invalid or expired');
  }

  const user = await prisma.user.findUnique({ where: { id: stored.userId } });
  if (!user) throw new UnauthorizedError('User not found');

  // Rotate: delete old, create new
  await prisma.refreshToken.delete({ where: { id: stored.id } });

  const newTokenValue = generateRefreshTokenValue();
  const expiresAt = new Date(now.getTime() + REFRESH_TOKEN_TTL_DAYS * 24 * 60 * 60 * 1000);
  await prisma.refreshToken.create({
    data: { userId: user.id, token: newTokenValue, expiresAt },
  });

  const accessToken = signAccessToken({ sub: user.id, role: user.role });
  return { accessToken, refreshToken: newTokenValue };
}

export async function logout(tokenValue: string): Promise<void> {
  const stored = await prisma.refreshToken.findUnique({ where: { token: tokenValue } });
  if (!stored) throw new ConflictError('Refresh token not found');
  await prisma.refreshToken.delete({ where: { id: stored.id } });
}
