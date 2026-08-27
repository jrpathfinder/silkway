import { Module } from '@nestjs/common';
import { IntegrationsModule } from '../integrations/integrations.module';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { OtpStore } from './otp-store.service';

@Module({
  imports: [IntegrationsModule],
  controllers: [AuthController],
  providers: [AuthService, OtpStore],
  exports: [AuthService],
})
export class AuthModule {}
