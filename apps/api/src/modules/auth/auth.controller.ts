import { Body, Controller, Post } from '@nestjs/common';
import { IsString, Matches } from 'class-validator';
import { AuthService } from './auth.service';

// E.164: "+" followed by 8–15 digits.
const PHONE_PATTERN = /^\+\d{8,15}$/;

class PhoneDto {
  @IsString()
  @Matches(PHONE_PATTERN, { message: 'phone must be in E.164 format, e.g. +79990000000' })
  phone!: string;
}

class VerifyOtpDto {
  @IsString()
  @Matches(PHONE_PATTERN, { message: 'phone must be in E.164 format, e.g. +79990000000' })
  phone!: string;

  @IsString()
  @Matches(/^\d{4,6}$/, { message: 'code must be 4-6 digits' })
  code!: string;
}

@Controller('auth/otp')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('request')
  async request(@Body() body: PhoneDto) {
    return { data: await this.auth.requestOtp(body.phone) };
  }

  @Post('verify')
  async verify(@Body() body: VerifyOtpDto) {
    return { data: await this.auth.verifyOtp(body.phone, body.code) };
  }
}
