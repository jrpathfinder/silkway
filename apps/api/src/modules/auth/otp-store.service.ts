import { Injectable } from '@nestjs/common';
import { createHash, randomInt } from 'node:crypto';

type OtpRecord = { codeHash: string; expiresAt: number; attempts: number };
type RateRecord = { lastSentAt: number; sentToday: number; dayKey: string };

const MAX_VERIFY_ATTEMPTS = 5;
const MIN_RESEND_INTERVAL_MS = 30_000;
const MAX_SENDS_PER_DAY = 10;

export type GenerateResult =
  | { allowed: true; code: string }
  | { allowed: false; retryAfterSeconds?: number };

/// Хранит коды в памяти процесса — переживёт один инстанс API, но не
/// перезапуск и не масштабирование на несколько инстансов. REDIS_URL уже
/// поднят в docker-compose и есть в .env.example — переезд на Redis-клиент
/// нужен до первого прод-деплоя с реальным SMS-провайдером, но не раньше:
/// до этого момента платить за настоящие SMS всё равно некому.
///
/// Лимиты (интервал между отправками, дневной лимит, попытки проверки) —
/// защита от накрутки чужого номера чужими деньгами в тот момент, когда за
/// SmsProvider стоит платный SMS.ru, а не MockSmsProvider.
@Injectable()
export class OtpStore {
  private readonly codes = new Map<string, OtpRecord>();
  private readonly rate = new Map<string, RateRecord>();

  generateAndStore(phone: string, ttlSeconds: number): GenerateResult {
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

  verify(phone: string, code: string): boolean {
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
