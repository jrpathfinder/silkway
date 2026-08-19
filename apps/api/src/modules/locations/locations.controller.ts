import { Controller, Get, Param } from '@nestjs/common';
import { LocationsService } from './locations.service';

@Controller('locations')
export class LocationsController {
  constructor(private readonly locations: LocationsService) {}

  @Get()
  list() {
    return { data: this.locations.listActive() };
  }

  @Get(':locationId')
  get(@Param('locationId') locationId: string) {
    return { data: this.locations.getById(locationId) ?? null };
  }
}
