import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createCipheriv, createDecipheriv, pbkdf2Sync, randomBytes } from 'crypto';

export type EncryptedValue = {
  cipherText: string;
  iv: string;
  authTag: string;
};

@Injectable()
export class CryptoService {
  private readonly encryptionKey: Buffer;

  constructor(private readonly configService: ConfigService) {
    const keyHex = this.configService.get<string>('MESSAGE_ENCRYPTION_KEY');

    if (!keyHex || keyHex.length !== 64) {
      throw new InternalServerErrorException(
        'MESSAGE_ENCRYPTION_KEY must be a 64-character hex string.',
      );
    }

    this.encryptionKey = Buffer.from(keyHex, 'hex');
  }

  encryptText(plainText: string): EncryptedValue {
    const iv = randomBytes(12);
    const cipher = createCipheriv('aes-256-gcm', this.encryptionKey, iv);

    const cipherText = Buffer.concat([
      cipher.update(plainText, 'utf8'),
      cipher.final(),
    ]).toString('hex');

    const authTag = cipher.getAuthTag().toString('hex');

    return {
      cipherText,
      iv: iv.toString('hex'),
      authTag,
    };
  }

  decryptText(encryptedValue: EncryptedValue): string {
    const decipher = createDecipheriv(
      'aes-256-gcm',
      this.encryptionKey,
      Buffer.from(encryptedValue.iv, 'hex'),
    );

    decipher.setAuthTag(Buffer.from(encryptedValue.authTag, 'hex'));

    return Buffer.concat([
      decipher.update(Buffer.from(encryptedValue.cipherText, 'hex')),
      decipher.final(),
    ]).toString('utf8');
  }

  generatePasswordSalt(): string {
    return randomBytes(16).toString('hex');
  }

  hashPassword(password: string, salt: string): string {
    return pbkdf2Sync(password, salt, 120000, 32, 'sha256').toString('hex');
  }
}
