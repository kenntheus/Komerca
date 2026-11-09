import { getEnv } from '../config/env';

interface SmsProvider {
  sendOtp(phone: string, code: string): Promise<void>;
}

class MockSmsProvider implements SmsProvider {
  async sendOtp(phone: string, code: string): Promise<void> {
    // In development, log the OTP code instead of sending an SMS
    console.log(`[OTP] phone=${phone} code=${code}`);
  }
}

class SemaphoreProvider implements SmsProvider {
  private readonly apiKey: string;

  constructor(apiKey: string) {
    this.apiKey = apiKey;
  }

  async sendOtp(phone: string, code: string): Promise<void> {
    const body = new URLSearchParams({
      apikey: this.apiKey,
      number: phone,
      message: `Your Komerca verification code is ${code}. Valid for 10 minutes.`,
      sendername: 'KOMERCA',
    });

    const res = await fetch('https://api.semaphore.co/api/v4/messages', {
      method: 'POST',
      body,
    });

    if (!res.ok) {
      throw new Error(`Semaphore SMS failed: ${res.status}`);
    }
  }
}

let _provider: SmsProvider | null = null;

export function getSmsProvider(): SmsProvider {
  if (!_provider) {
    const env = getEnv();
    if (env.SMS_PROVIDER === 'semaphore' && env.SEMAPHORE_API_KEY) {
      _provider = new SemaphoreProvider(env.SEMAPHORE_API_KEY);
    } else {
      _provider = new MockSmsProvider();
    }
  }
  return _provider;
}

export function resetSmsProvider(): void {
  _provider = null;
}
