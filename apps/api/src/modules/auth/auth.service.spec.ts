import { SmsProvider } from '../integrations/ports/sms.port';
import { AuthService } from './auth.service';
import { OtpStore } from './otp-store.service';

class TestSmsProvider implements SmsProvider {
  sent: Array<{ phone: string; message: string }> = [];

  async send(phoneE164: string, message: string): Promise<void> {
    this.sent.push({ phone: phoneE164, message });
  }
}

describe('AuthService', () => {
  let sms: TestSmsProvider;
  let service: AuthService;

  beforeEach(() => {
    sms = new TestSmsProvider();
    service = new AuthService(sms, new OtpStore());
  });

  it('sends a generated code through the SMS provider and accepts the request', async () => {
    const result = await service.requestOtp('+79990000000');
    expect(result.accepted).toBe(true);
    expect(sms.sent).toHaveLength(1);
    expect(sms.sent[0].phone).toBe('+79990000000');
    expect(sms.sent[0].message).toMatch(/\d{6}/);
  });

  it('verifies the exact code that was sent', async () => {
    await service.requestOtp('+79990000001');
    const code = sms.sent[0].message.match(/\d{6}/)![0];

    const result = service.verifyOtp('+79990000001', code) as { accessToken: string; user: { phone: string } };
    expect(result.accessToken).toBe('dev-access-token');
    expect(result.user.phone).toBe('+79990000001');
  });

  it('rejects a wrong code', async () => {
    await service.requestOtp('+79990000002');
    const result = service.verifyOtp('+79990000002', '000000');
    expect(result).toEqual({ verified: false });
  });

  it('rejects a resend request before the throttle interval elapses', async () => {
    await service.requestOtp('+79990000003');
    const second = await service.requestOtp('+79990000003');
    expect(second.accepted).toBe(false);
  });
});
