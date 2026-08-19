import { Controller, Get, Param } from '@nestjs/common';
import { CatalogService } from './catalog.service';

@Controller('locations/:locationId/catalog')
export class CatalogController {
  constructor(private readonly catalog: CatalogService) {}

  @Get()
  async getCatalog(@Param('locationId') locationId: string) {
    return { data: await this.catalog.getForLocation(locationId) };
  }
}
