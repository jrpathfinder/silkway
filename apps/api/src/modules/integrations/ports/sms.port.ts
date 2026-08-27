export abstract class SmsProvider {
  abstract send(phoneE164: string, message: string): Promise<void>;
}
