import { Module } from '@nestjs/common';
import { CatalogModule } from '../catalog/catalog.module';
import { LocationsModule } from '../locations/locations.module';
import { IntegrationsModule } from '../integrations/integrations.module';
import { CourierOrdersController } from './courier-orders.controller';
import { OrdersController } from './orders.controller';
import { OrdersService } from './orders.service';

@Module({
  imports: [CatalogModule, LocationsModule, IntegrationsModule],
  controllers: [OrdersController, CourierOrdersController],
  providers: [OrdersService],
  exports: [OrdersService],
})
export class OrdersModule {}
