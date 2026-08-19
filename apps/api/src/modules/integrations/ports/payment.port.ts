export type CreatePaymentRequest = {
  orderId: string;
  amountRub: number;
  description: string;
};

export type PaymentCheckout = {
  id: string;
  status: 'pending' | 'succeeded' | 'cancelled';
  confirmationUrl: string;
};

export abstract class PaymentProvider {
  abstract createPayment(request: CreatePaymentRequest): Promise<PaymentCheckout>;
  abstract refund(paymentId: string, amountRub?: number): Promise<void>;
}
