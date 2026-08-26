import { Module } from '@nestjs/common';
import { HealthModule } from './modules/health/health.module';
import { LocationsModule } from './modules/locations/locations.module';
import { CatalogModule } from './modules/catalog/catalog.module';
import { AuthModule } from './modules/auth/auth.module';
import { AdminModule } from './modules/admin/admin.module';
import { OrdersModule } from './modules/orders/orders.module';
import { IntegrationsModule } from './modules/integrations/integrations.module';
import { DatabaseModule } from './database/database.module';

@Module({
  imports: [
    DatabaseModule,
    HealthModule,
    LocationsModule,
    CatalogModule,
    AuthModule,
    AdminModule,
    OrdersModule,
    IntegrationsModule,
  ],
})
export class AppModule {}
