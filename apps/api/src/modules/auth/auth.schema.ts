import { z } from 'zod';

export const RequestOtpSchema = z.object({
  phone: z
    .string()
    .regex(/^\+639\d{9}$/, 'Phone must be in format +639XXXXXXXXX'),
});

export const VerifyOtpSchema = z.object({
  phone: z
    .string()
    .regex(/^\+639\d{9}$/, 'Phone must be in format +639XXXXXXXXX'),
  code: z.string().length(6, 'OTP code must be 6 digits').regex(/^\d{6}$/, 'OTP code must be digits only'),
});

export const RefreshTokenSchema = z.object({
  refreshToken: z.string().min(1),
});

export const LogoutSchema = z.object({
  refreshToken: z.string().min(1),
});
