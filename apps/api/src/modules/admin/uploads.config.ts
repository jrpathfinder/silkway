import { join } from 'node:path';

/// Where uploaded catalog-item photos land on disk. Defaults to a directory
/// next to the running process (apps/api/uploads in local dev; set
/// UPLOADS_DIR to an absolute, persisted path — e.g. a mounted volume — in
/// any deployment where the container filesystem doesn't survive restarts).
export function uploadsDir(): string {
  return process.env.UPLOADS_DIR ?? join(process.cwd(), 'uploads');
}

export const UPLOADS_URL_PREFIX = '/uploads';
