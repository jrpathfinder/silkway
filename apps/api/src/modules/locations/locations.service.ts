import { Injectable } from '@nestjs/common';

export type RestaurantLocation = {
  id: string;
  cityId: string;
  name: string;
  address: string;
  timezone: string;
  isActive: boolean;
};

@Injectable()
export class LocationsService {
  private readonly locations: RestaurantLocation[] = [
    {
      id: 'ca-moscow-1',
      cityId: 'moscow',
      name: 'Central Asia Restaurant — Москва',
      address: 'Москва, адрес будет указан при запуске',
      timezone: 'Europe/Moscow',
      isActive: true,
    },
  ];

  listActive(): RestaurantLocation[] {
    return this.locations.filter((location) => location.isActive);
  }

  getById(id: string): RestaurantLocation | undefined {
    return this.locations.find((location) => location.id === id && location.isActive);
  }
}
