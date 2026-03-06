import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { ServiceAccount, cert, getApps, initializeApp } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);
  private readonly enabled: boolean;

  constructor(private readonly configService: ConfigService) {
    this.enabled = this.initializeFirebase();
  }

  async sendPushNotification(params: {
    tokens: string[];
    title: string;
    body: string;
    data?: Record<string, string>;
  }) {
    if (!this.enabled) {
      return;
    }

    const uniqueTokens = Array.from(
      new Set(
        params.tokens
          .map((token) => token.trim())
          .filter((token) => token.length > 0),
      ),
    );

    if (uniqueTokens.length === 0) {
      return;
    }

    try {
      const response = await getMessaging().sendEachForMulticast({
        tokens: uniqueTokens,
        notification: {
          title: params.title,
          body: params.body,
        },
        data: params.data,
        android: { priority: 'high' },
      });

      if (response.failureCount > 0) {
        this.logger.warn(
          `Push delivery partial failure: ${response.failureCount}/${response.responses.length}`,
        );
      }
    } catch (error) {
      const stack = error instanceof Error ? error.stack : undefined;
      this.logger.error('Failed to send push notification.', stack);
    }
  }

  private initializeFirebase(): boolean {
    const rawServiceAccount = this.resolveServiceAccountJson();

    if (rawServiceAccount.trim().length === 0) {
      this.logger.warn(
        'Firebase service account is missing. Set FIREBASE_SERVICE_ACCOUNT_JSON or FIREBASE_SERVICE_ACCOUNT_PATH.',
      );
      return false;
    }

    try {
      const serviceAccount = JSON.parse(rawServiceAccount) as ServiceAccount;

      if (getApps().length === 0) {
        initializeApp({
          credential: cert(serviceAccount),
        });
      }

      return true;
    } catch (error) {
      const stack = error instanceof Error ? error.stack : undefined;
      this.logger.error(
        'Invalid Firebase service account credentials. Push notifications are disabled.',
        stack,
      );
      return false;
    }
  }

  private resolveServiceAccountJson(): string {
    const jsonFromEnv =
      this.configService.get<string>('FIREBASE_SERVICE_ACCOUNT_JSON') ?? '';
    if (jsonFromEnv.trim().length > 0) {
      return jsonFromEnv;
    }

    const configuredPath =
      this.configService.get<string>('FIREBASE_SERVICE_ACCOUNT_PATH') ??
      'serviceAccountKey.json';
    const absolutePath = join(process.cwd(), configuredPath);

    if (!existsSync(absolutePath)) {
      return '';
    }

    try {
      return readFileSync(absolutePath, 'utf8');
    } catch (error) {
      const stack = error instanceof Error ? error.stack : undefined;
      this.logger.error(
        `Failed to read Firebase service account file at ${absolutePath}.`,
        stack,
      );
      return '';
    }
  }
}
