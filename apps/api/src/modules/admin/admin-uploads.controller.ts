import { BadRequestException, Controller, Post, UploadedFile, UseGuards, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { randomUUID } from 'node:crypto';
import { extname } from 'node:path';
import { diskStorage } from 'multer';
import { AdminAuthGuard } from './admin-auth.guard';
import { UPLOADS_URL_PREFIX, uploadsDir } from './uploads.config';

const ALLOWED_MIME_TYPES: Record<string, string> = {
  'image/jpeg': '.jpg',
  'image/png': '.png',
  'image/webp': '.webp',
};
const MAX_FILE_SIZE_BYTES = 5 * 1024 * 1024;

/// Self-hosted alternative to pasting an external image URL — the admin
/// panel's item form uploads here and gets back an absolute URL to store as
/// CatalogItem.imageUrl (see ItemsPanel.tsx). Files are served back out by
/// main.ts's static-assets mount, not through a Nest controller.
@UseGuards(AdminAuthGuard)
@Controller('admin/uploads')
export class AdminUploadsController {
  @Post()
  @UseInterceptors(
    FileInterceptor('file', {
      storage: diskStorage({
        destination: (_req, _file, callback) => callback(null, uploadsDir()),
        filename: (_req, file, callback) => {
          const extension = ALLOWED_MIME_TYPES[file.mimetype] ?? extname(file.originalname);
          callback(null, `${randomUUID()}${extension}`);
        },
      }),
      limits: { fileSize: MAX_FILE_SIZE_BYTES },
      fileFilter: (_req, file, callback) => {
        if (!ALLOWED_MIME_TYPES[file.mimetype]) {
          callback(new BadRequestException('Только JPEG, PNG или WebP'), false);
          return;
        }
        callback(null, true);
      },
    }),
  )
  upload(@UploadedFile() file?: Express.Multer.File) {
    if (!file) throw new BadRequestException('Файл не получен');
    const base = process.env.PUBLIC_BASE_URL ?? 'http://localhost:3000';
    return { data: { url: `${base}${UPLOADS_URL_PREFIX}/${file.filename}` } };
  }
}
