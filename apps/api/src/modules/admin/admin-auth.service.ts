import { Injectable, UnauthorizedException } from '@nestjs/common';
import { safeEqual, signAdminToken } from './admin-token.util';

@Injectable()
export class AdminAuthService {
  login(password: string) {
    const expected = process.env.ADMIN_PASSWORD;
    if (!expected) throw new UnauthorizedException('ADMIN_PASSWORD is not configured on the server.');
    if (!safeEqual(password, expected)) throw new UnauthorizedException('Неверный пароль');
    return signAdminToken();
  }
}
