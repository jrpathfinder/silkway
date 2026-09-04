import { Injectable, Logger, OnModuleDestroy } from '@nestjs/common';
import Redis from 'ioredis';

/// Optional, same fallback shape as DatabaseService — features that use this
/// (currently OtpStore) must keep working with in-process fallbacks when
/// REDIS_URL isn't set, rather than making Redis a hard dependency.
@Injectable()
export class RedisService implements OnModuleDestroy {
  private readonly logger = new Logger(RedisService.name);
  private readonly conn?: Redis;

  constructor() {
    const url = process.env.REDIS_URL;
    if (url) {
      this.conn = new Redis(url, { maxRetriesPerRequest: 3 });
      this.conn.on('error', (error) => this.logger.error(`Redis connection error: ${error.message}`));
    } else {
      this.logger.warn('REDIS_URL is not configured; Redis-backed features use in-process fallbacks.');
    }
  }

  get enabled(): boolean {
    return Boolean(this.conn);
  }

  get client(): Redis {
    if (!this.conn) throw new Error('Redis is not configured');
    return this.conn;
  }

  async onModuleDestroy(): Promise<void> {
    await this.conn?.quit();
  }
}
