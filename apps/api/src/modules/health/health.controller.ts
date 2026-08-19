import { Controller, Get } from '@nestjs/common';

@Controller('health')
export class HealthController {
  @Get()
  check() {
    return {
      status: 'ok',
      service: 'central-asia-api',
      environment: process.env.NODE_ENV ?? 'development',
      time: new Date().toISOString(),
    };
  }
}
