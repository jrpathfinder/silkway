export type Nutrition = {
  caloriesKcal: number;
  proteinG: number;
  fatG: number;
  carbsG: number;
};

export type Category = {
  id: string;
  name: string;
  sortOrder: number;
};

export type Modifier = {
  id: string;
  itemId: string;
  name: string;
  priceRub: number;
};

export type Item = {
  id: string;
  categoryId: string;
  name: string;
  description: string;
  priceRub: number;
  isAvailable: boolean;
  imageUrl?: string;
  weightLabel?: string;
  composition?: string;
  modifierGroupLabel?: string;
  ratingPercent?: number;
  ratingCount?: number;
  nutritionPer100g?: Nutrition;
  modifiers?: Modifier[];
};

export type Promotion = {
  id: string;
  name: string;
  discountType: 'percent' | 'fixed';
  discountValue: number;
  itemId?: string;
  categoryId?: string;
  startsAt?: string;
  endsAt?: string;
  isActive: boolean;
};

export type CatalogExport = {
  categories: Category[];
  items: Item[];
  promotions: Promotion[];
};

export type OrderStatus =
  | 'PENDING_PAYMENT'
  | 'PAID'
  | 'ACCEPTED'
  | 'PREPARING'
  | 'READY_FOR_DELIVERY'
  | 'IN_DELIVERY'
  | 'DELIVERED'
  | 'CANCELLED'
  | 'REFUNDED';

export type OrderLine = {
  itemId: string;
  name: string;
  quantity: number;
  unitPriceRub: number;
  modifierIds: string[];
};

export type DeliveryAddress = {
  lat: number;
  lng: number;
  addressText: string;
  comment?: string;
};

export type Order = {
  id: string;
  locationId: string;
  customerId: string;
  lines: OrderLine[];
  totalRub: number;
  status: OrderStatus;
  createdAt: string;
  paymentId?: string;
  fulfillmentType: 'DELIVERY' | 'PICKUP';
  deliveryAddress?: DeliveryAddress;
};
