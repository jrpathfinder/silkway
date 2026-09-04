import 'reflect-metadata';
import 'dotenv/config';
import { mkdirSync } from 'node:fs';
import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { AppModule } from './app.module';
import { UPLOADS_URL_PREFIX, uploadsDir } from './modules/admin/uploads.config';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  app.setGlobalPrefix('v1');
  app.enableCors();
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));

  // Uploaded catalog-item photos (see AdminUploadsController) — served as
  // plain static files, outside the /v1 API prefix, same as any CDN would.
  mkdirSync(uploadsDir(), { recursive: true });
  app.useStaticAssets(uploadsDir(), { prefix: UPLOADS_URL_PREFIX });

  await app.listen(Number(process.env.PORT ?? 3000));
}

void bootstrap();
