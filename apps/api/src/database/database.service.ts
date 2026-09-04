import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { Pool, QueryResult, QueryResultRow } from 'pg';
import { readFile } from 'node:fs/promises';
import { join } from 'node:path';

@Injectable()
export class DatabaseService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(DatabaseService.name);
  private readonly pool?: Pool;

  constructor() {
    const connectionString = process.env.DATABASE_URL;
    if (connectionString) {
      // Managed Postgres (Timeweb DBaaS, RDS, ...) typically requires TLS on
      // the connection; local docker-compose Postgres doesn't speak it at
      // all, so this stays opt-in rather than always-on. rejectUnauthorized
      // is off because most managed providers hand out certs from an
      // internal CA the Node trust store doesn't know — the connection is
      // still encrypted, just not chain-verified.
      const ssl = process.env.DATABASE_SSL === 'true' ? { rejectUnauthorized: false } : undefined;
      this.pool = new Pool({ connectionString, max: Number(process.env.DB_POOL_SIZE ?? 10), ssl });
    } else {
      this.logger.warn('DATABASE_URL is not configured; database-backed features use development fallbacks.');
    }
  }

  get enabled(): boolean {
    return Boolean(this.pool);
  }

  async onModuleInit(): Promise<void> {
    if (!this.pool) return;

    // Relative to this compiled file's own location, not the process cwd —
    // "npm run start:dev" (ts-node, cwd = apps/api) and "node dist/main.js"
    // (production, cwd could be anything) both resolve correctly this way.
    // The build script copies schema.sql next to the compiled .js for this.
    const schemaPath = join(__dirname, 'schema.sql');
    const schema = await readFile(schemaPath, 'utf8');
    await this.pool.query(schema);
    this.logger.log('PostgreSQL schema is ready.');
  }

  query<T extends QueryResultRow = QueryResultRow>(text: string, values?: unknown[]): Promise<QueryResult<T>> {
    if (!this.pool) throw new Error('PostgreSQL is not configured');
    return this.pool.query<T>(text, values);
  }

  async onModuleDestroy(): Promise<void> {
    await this.pool?.end();
  }
}
