import { createHmac, timingSafeEqual } from 'node:crypto';

const TOKEN_TTL_MS = 12 * 60 * 60 * 1000;

function getSecret(): string {
  const secret = process.env.ADMIN_SESSION_SECRET;
  if (!secret) throw new Error('ADMIN_SESSION_SECRET is not configured — set it before using the admin panel.');
  return secret;
}

function sign(payload: string): string {
  return createHmac('sha256', getSecret()).update(payload).digest('base64url');
}

/// Постоянного сравнения строк тут ровно два места (пароль и подпись
/// токена) — своя утилита вместо `===`, чтобы не сравнивать секреты по
/// времени выполнения.
export function safeEqual(a: string, b: string): boolean {
  const bufA = Buffer.from(a);
  const bufB = Buffer.from(b);
  return bufA.length === bufB.length && timingSafeEqual(bufA, bufB);
}

export function signAdminToken(): { token: string; expiresAt: string } {
  const exp = Date.now() + TOKEN_TTL_MS;
  const payload = Buffer.from(JSON.stringify({ exp })).toString('base64url');
  return { token: `${payload}.${sign(payload)}`, expiresAt: new Date(exp).toISOString() };
}

export function verifyAdminToken(token: string | undefined): boolean {
  if (!token) return false;
  const [payload, signature] = token.split('.');
  if (!payload || !signature) return false;
  if (!safeEqual(signature, sign(payload))) return false;

  try {
    const { exp } = JSON.parse(Buffer.from(payload, 'base64url').toString('utf8')) as { exp: number };
    return typeof exp === 'number' && Date.now() < exp;
  } catch {
    return false;
  }
}
