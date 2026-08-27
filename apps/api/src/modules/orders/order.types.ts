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

export type FulfillmentType = 'DELIVERY' | 'PICKUP';

export type DeliveryAddress = {
  lat: number;
  lng: number;
  addressText: string;
  comment?: string;
};

export type OrderLine = {
  itemId: string;
  name: string;
  quantity: number;
  unitPriceRub: number;
  modifierIds: string[];
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
  fulfillmentType: FulfillmentType;
  deliveryAddress?: DeliveryAddress;
};
