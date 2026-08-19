export type DeliveryQuoteRequest = { locationId: string; address: string; orderId: string };
export type DeliveryQuote = { provider: string; amountRub: number; etaMinutes: number };

export interface DeliveryProvider {
  quote(request: DeliveryQuoteRequest): Promise<DeliveryQuote>;
  create(request: DeliveryQuoteRequest): Promise<{ id: string; status: string }>;
  cancel(deliveryId: string): Promise<void>;
}
