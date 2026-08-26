import { Module } from '@nestjs/common';
import { AdminAuthController } from './admin-auth.controller';
import { AdminAuthService } from './admin-auth.service';
import { AdminCatalogController } from './admin-catalog.controller';
import { AdminCatalogService } from './admin-catalog.service';
import { AdminImportExportService } from './admin-import-export.service';
import { AdminPromotionsController } from './admin-promotions.controller';
import { AdminPromotionsService } from './admin-promotions.service';

@Module({
  controllers: [AdminAuthController, AdminCatalogController, AdminPromotionsController],
  providers: [AdminAuthService, AdminCatalogService, AdminPromotionsService, AdminImportExportService],
})
export class AdminModule {}
