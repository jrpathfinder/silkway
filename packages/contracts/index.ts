export type ApiResponse<T> = { data: T; requestId?: string };

export type Location = {
  id: string;
  cityId: string;
  name: string;
  address: string;
  timezone: string;
  isActive: boolean;
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
