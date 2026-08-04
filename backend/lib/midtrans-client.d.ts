declare module 'midtrans-client' {
  interface CoreApiOptions {
    isProduction: boolean;
    serverKey: string;
    clientKey: string;
  }

  interface ChargePayload {
    payment_type: string;
    transaction_details: { order_id: string; gross_amount: number };
    custom_field1?: string;
    bank_transfer?: { bank: string };
    echannel?: { bill_info1: string; bill_info2: string };
  }

  interface ChargeAction {
    name: string;
    method: string;
    url: string;
  }

  interface ChargeResponse {
    actions?: ChargeAction[];
    va_numbers?: { bank: string; va_number: string }[];
    permata_va_number?: string;
    bill_key?: string;
    biller_code?: string;
    transaction_status?: string;
    [key: string]: unknown;
  }

  class CoreApi {
    constructor(options: CoreApiOptions);
    charge(payload: ChargePayload): Promise<ChargeResponse>;
    transaction: {
      status(orderId: string): Promise<ChargeResponse>;
    };
  }

  const _default: { CoreApi: typeof CoreApi };
  export default _default;
}
