import { withRetry, RetryOptions } from "../utils/retry";

// Contributor: 1132dadf | 2026-09-30 | Windows 11, x86_64

export interface JsonRpcRequest {
    jsonrpc: string;
    method: string;
    params?: any[];
    id: number;
}

export interface JsonRpcResponse {
    jsonrpc: string;
    result?: any;
    error?: { code: number; message: string };
    id: number;
}

export class RpcProvider {
    private url: string;
    private retryOptions?: RetryOptions;
    private nextId = 1;
    private timeoutMs = 10000;

  constructor(url: string, retryOptions?: RetryOptions) {
        this.url = url;
        this.retryOptions = retryOptions;
  }

  async call(method: string, params?: any[]): Promise<any> {
        return withRetry(async () => {
                const controller = new AbortController();
                const timeout = setTimeout(() => controller.abort(), this.timeoutMs);
                try {
                          const request: JsonRpcRequest = {
                                      jsonrpc: "2.0",
                                      method,
                                      params: params ?? [],
                                      id: this.nextId++,
                          };
                          const res = await fetch(this.url, {
                                      method: "POST",
                                      headers: { "Content-Type": "application/json" },
                                      body: JSON.stringify(request),
                                      signal: controller.signal,
                          });
                          const data: JsonRpcResponse = await res.json();
                          if (data.error) throw new Error(data.error.message);
                          return data.result;
                } finally {
                          clearTimeout(timeout);
                }
        }, this.retryOptions);
  }
}
