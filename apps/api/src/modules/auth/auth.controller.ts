import { Body, Controller, Post } from '@nestjs/common';
import { AuthService } from './auth.service';

class PhoneDto { phone!: string; }
class VerifyOtpDto { phone!: string; code!: string; }

@Controller('auth/otp')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('request')
  request(@Body() body: PhoneDto) {
    return { data: this.auth.requestOtp(body.phone) };
  }

  @Post('verify')
  verify(@Body() body: VerifyOtpDto) {
    return { data: this.auth.verifyOtp(body.phone, body.code) };
  }
}
