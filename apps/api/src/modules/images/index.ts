import { createHash } from 'crypto';
import { getEnv } from '../../config/env';

export interface SignPhotoResult {
  provider: 'cloudinary' | 'local';
  uploadUrl?: string;
  apiKey?: string;
  timestamp?: number;
  signature?: string;
  folder?: string;
  publicId: string;
}

export interface ImageAdapter {
  signUpload(listingId: string): Promise<SignPhotoResult>;
  deletePhoto(publicId: string): Promise<void>;
}

class LocalAdapter implements ImageAdapter {
  async signUpload(listingId: string): Promise<SignPhotoResult> {
    const publicId = `local_${listingId}_${Date.now()}`;
    return {
      provider: 'local',
      publicId,
    };
  }

  async deletePhoto(_publicId: string): Promise<void> {
    // Local adapter: nothing to delete from external storage
  }
}

class CloudinaryAdapter implements ImageAdapter {
  private cloudName: string;
  private apiKey: string;
  private apiSecret: string;

  constructor(cloudName: string, apiKey: string, apiSecret: string) {
    this.cloudName = cloudName;
    this.apiKey = apiKey;
    this.apiSecret = apiSecret;
  }

  async signUpload(listingId: string): Promise<SignPhotoResult> {
    const timestamp = Math.floor(Date.now() / 1000);
    const folder = `komerca/listings/${listingId}`;
    const params: Record<string, string | number> = { folder, timestamp };

    const str = Object.entries(params)
      .sort(([a], [b]) => a.localeCompare(b))
      .map(([k, v]) => `${k}=${v}`)
      .join('&');
    const signature = createHash('sha256').update(str + this.apiSecret).digest('hex');

    return {
      provider: 'cloudinary',
      uploadUrl: `https://api.cloudinary.com/v1_1/${this.cloudName}/image/upload`,
      apiKey: this.apiKey,
      timestamp,
      signature,
      folder,
      publicId: '',
    };
  }

  async deletePhoto(publicId: string): Promise<void> {
    const timestamp = Math.floor(Date.now() / 1000);
    const str = `public_id=${publicId}&timestamp=${timestamp}`;
    const signature = createHash('sha256').update(str + this.apiSecret).digest('hex');

    const body = new URLSearchParams({
      public_id: publicId,
      timestamp: timestamp.toString(),
      api_key: this.apiKey,
      signature,
    });

    await fetch(`https://api.cloudinary.com/v1_1/${this.cloudName}/image/destroy`, {
      method: 'POST',
      body,
    });
  }
}

let _adapter: ImageAdapter | null = null;

export function getImageAdapter(): ImageAdapter {
  if (!_adapter) {
    const env = getEnv();
    if (env.IMAGE_STORAGE === 'cloudinary') {
      _adapter = new CloudinaryAdapter(
        env.CLOUDINARY_CLOUD_NAME ?? '',
        env.CLOUDINARY_API_KEY ?? '',
        env.CLOUDINARY_API_SECRET ?? '',
      );
    } else {
      _adapter = new LocalAdapter();
    }
  }
  return _adapter;
}

export function resetImageAdapter(): void {
  _adapter = null;
}
