export type MarketplaceMenuSnapshot = { locationId: string; version: string; items: unknown[] };

export interface MarketplaceMenuAdapter {
  publishMenu(snapshot: MarketplaceMenuSnapshot): Promise<void>;
  pullOrders(): Promise<unknown[]>;
  acknowledgeOrder(externalOrderId: string): Promise<void>;
}
