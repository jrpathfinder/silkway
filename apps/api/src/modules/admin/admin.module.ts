import { Module } from '@nestjs/common';
import { OrdersModule } from '../orders/orders.module';
import { AdminAuthController } from './admin-auth.controller';
import { AdminAuthService } from './admin-auth.service';
import { AdminCatalogController } from './admin-catalog.controller';
import { AdminCatalogService } from './admin-catalog.service';
import { AdminImportExportService } from './admin-import-export.service';
import { AdminOrdersController } from './admin-orders.controller';
import { AdminPromotionsController } from './admin-promotions.controller';
import { AdminPromotionsService } from './admin-promotions.service';
import { AdminUploadsController } from './admin-uploads.controller';

@Module({
  imports: [OrdersModule],
  controllers: [AdminAuthController, AdminCatalogController, AdminPromotionsController, AdminOrdersController, AdminUploadsController],
  providers: [AdminAuthService, AdminCatalogService, AdminPromotionsService, AdminImportExportService],
})
export class AdminModule {}
