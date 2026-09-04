import { Injectable } from '@nestjs/common';
import { createHash, randomInt } from 'node:crypto';
import { RedisService } from '../../redis/redis.service';

type OtpRecord = { codeHash: string; expiresAt: number; attempts: number };
type RateRecord = { lastSentAt: number; sentToday: number; dayKey: string };
type StoredCode = { codeHash: string; attempts: number };

const MAX_VERIFY_ATTEMPTS = 5;
const MIN_RESEND_INTERVAL_MS = 30_000;
const MIN_RESEND_INTERVAL_SECONDS = MIN_RESEND_INTERVAL_MS / 1000;
const MAX_SENDS_PER_DAY = 10;
const DAILY_KEY_TTL_SECONDS = 25 * 60 * 60; // outlives a calendar day so a late-UTC dayKey still expires

export type GenerateResult =
  | { allowed: true; code: string }
  | { allowed: false; retryAfterSeconds?: number };

/// Rate-limit/code state — Redis-backed when REDIS_URL is configured (needed
/// once there's more than one API instance, or the process restarts and a
/// resend-cooldown/daily-limit shouldn't just reset); otherwise falls back to
/// an in-process Map, which is what the existing tests exercise (they build
/// `new OtpStore()` directly, with no Redis available).
///
/// Лимиты (интервал между отправками, дневной лимит, попытки проверки) —
/// защита от накрутки чужого номера чужими деньгами в тот момент, когда за
/// SmsProvider стоит платный SMS.ru, а не MockSmsProvider.
@Injectable()
export class OtpStore {
  private readonly codes = new Map<string, OtpRecord>();
  private readonly rate = new Map<string, RateRecord>();

  constructor(private readonly redis?: RedisService) {}

  async generateAndStore(phone: string, ttlSeconds: number): Promise<GenerateResult> {
    return this.redis?.enabled ? this.generateAndStoreRedis(phone, ttlSeconds) : this.generateAndStoreMemory(phone, ttlSeconds);
  }

  async verify(phone: string, code: string): Promise<boolean> {
    return this.redis?.enabled ? this.verifyRedis(phone, code) : this.verifyMemory(phone, code);
  }

  private async generateAndStoreRedis(phone: string, ttlSeconds: number): Promise<GenerateResult> {
    const client = this.redis!.client;
    const cooldownKey = `otp:cooldown:${phone}`;
    const setCooldown = await client.set(cooldownKey, '1', 'EX', MIN_RESEND_INTERVAL_SECONDS, 'NX');
    if (setCooldown === null) {
      const retryAfterSeconds = await client.ttl(cooldownKey);
      return { allowed: false, retryAfterSeconds: retryAfterSeconds > 0 ? retryAfterSeconds : MIN_RESEND_INTERVAL_SECONDS };
    }

    const dayKey = new Date().toISOString().slice(0, 10);
    const dailyKey = `otp:daily:${phone}:${dayKey}`;
    const sentToday = await client.incr(dailyKey);
    if (sentToday === 1) await client.expire(dailyKey, DAILY_KEY_TTL_SECONDS);
    if (sentToday > MAX_SENDS_PER_DAY) return { allowed: false };

    const code = String(randomInt(0, 1_000_000)).padStart(6, '0');
    const stored: StoredCode = { codeHash: this.hash(phone, code), attempts: 0 };
    await client.set(`otp:code:${phone}`, JSON.stringify(stored), 'EX', ttlSeconds);
    return { allowed: true, code };
  }

  private async verifyRedis(phone: string, code: string): Promise<boolean> {
    const client = this.redis!.client;
    const key = `otp:code:${phone}`;
    const raw = await client.get(key);
    if (!raw) return false;

    const record = JSON.parse(raw) as StoredCode;
    record.attempts++;
    if (record.attempts > MAX_VERIFY_ATTEMPTS) {
      await client.del(key);
      return false;
    }

    const ok = record.codeHash === this.hash(phone, code);
    if (ok) {
      await client.del(key);
    } else {
      // Preserve the code's remaining TTL — this write is only tracking the
      // attempt count, not resetting how long the code stays valid.
      await client.set(key, JSON.stringify(record), 'KEEPTTL');
    }
    return ok;
  }

  private generateAndStoreMemory(phone: string, ttlSeconds: number): GenerateResult {
    const now = Date.now();
    const dayKey = new Date(now).toISOString().slice(0, 10);
    const rate = this.rate.get(phone);

    if (rate && now - rate.lastSentAt < MIN_RESEND_INTERVAL_MS) {
      return { allowed: false, retryAfterSeconds: Math.ceil((MIN_RESEND_INTERVAL_MS - (now - rate.lastSentAt)) / 1000) };
    }
    if (rate && rate.dayKey === dayKey && rate.sentToday >= MAX_SENDS_PER_DAY) {
      return { allowed: false };
    }

    const code = String(randomInt(0, 1_000_000)).padStart(6, '0');
    this.codes.set(phone, { codeHash: this.hash(phone, code), expiresAt: now + ttlSeconds * 1000, attempts: 0 });
    this.rate.set(phone, {
      lastSentAt: now,
      sentToday: rate?.dayKey === dayKey ? rate.sentToday + 1 : 1,
      dayKey,
    });
    return { allowed: true, code };
  }

  private verifyMemory(phone: string, code: string): boolean {
    const record = this.codes.get(phone);
    if (!record) return false;
    if (Date.now() > record.expiresAt) {
      this.codes.delete(phone);
      return false;
    }

    record.attempts++;
    if (record.attempts > MAX_VERIFY_ATTEMPTS) {
      this.codes.delete(phone);
      return false;
    }

    const ok = record.codeHash === this.hash(phone, code);
    if (ok) this.codes.delete(phone);
    return ok;
  }

  private hash(phone: string, code: string): string {
    const secret = process.env.OTP_HASH_SECRET ?? 'dev-only-insecure-secret';
    return createHash('sha256').update(`${phone}:${code}:${secret}`).digest('hex');
  }
}
