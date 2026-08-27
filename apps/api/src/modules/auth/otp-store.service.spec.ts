import { OtpStore } from './otp-store.service';

function requireCode(store: OtpStore, phone: string, ttlSeconds: number): string {
  const result = store.generateAndStore(phone, ttlSeconds);
  if (!result.allowed) throw new Error('expected generateAndStore to be allowed');
  return result.code;
}

describe('OtpStore', () => {
  it('verifies the exact generated code once, then rejects reuse', () => {
    const store = new OtpStore();
    const code = requireCode(store, '+79990000000', 300);

    expect(store.verify('+79990000000', code)).toBe(true);
    expect(store.verify('+79990000000', code)).toBe(false);
  });

  it('rejects a wrong code without consuming the real one', () => {
    const store = new OtpStore();
    const code = requireCode(store, '+79990000001', 300);

    expect(store.verify('+79990000001', '000000')).toBe(false);
    expect(store.verify('+79990000001', code)).toBe(true);
  });

  it('rejects verification for a phone that never requested a code', () => {
    const store = new OtpStore();
    expect(store.verify('+79990000002', '123456')).toBe(false);
  });

  it('rejects an expired code', async () => {
    const store = new OtpStore();
    const code = requireCode(store, '+79990000003', 0);
    await new Promise((resolve) => setTimeout(resolve, 5));
    expect(store.verify('+79990000003', code)).toBe(false);
  });

  it('throttles resending before the minimum interval elapses', () => {
    const store = new OtpStore();
    expect(store.generateAndStore('+79990000004', 300).allowed).toBe(true);
    const second = store.generateAndStore('+79990000004', 300);
    expect(second.allowed).toBe(false);
  });
});
