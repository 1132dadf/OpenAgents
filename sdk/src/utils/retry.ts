/**
 * Retry utility with exponential backoff for unreliable RPC calls.
 * Contributor: 1132dadf | 2026-09-30 | Windows 11, x86_64
 */

export interface RetryOptions {
    maxRetries?: number;
    baseDelayMs?: number;
    maxDelayMs?: number;
    onRetry?: (attempt: number, error: Error) => void;
}

const DEFAULT_OPTIONS: Required<Omit<RetryOptions, "onRetry">> = {
    maxRetries: 5,
    baseDelayMs: 500,
    maxDelayMs: 60_000,
};

export class RetryHandler {
    private options: Required<Omit<RetryOptions, "onRetry">>;
    private onRetry?: (attempt: number, error: Error) => void;
    private consecutiveFailures = 0;

  constructor(options: RetryOptions = {}) {
        this.options = { ...DEFAULT_OPTIONS, ...options };
        this.onRetry = options.onRetry;
  }

  async execute<T>(fn: () => Promise<T>): Promise<T> {
        let lastError: Error | undefined;

      for (let attempt = 0; attempt <= this.options.maxRetries; attempt++) {
              try {
                        const result = await fn();
                        this.consecutiveFailures = 0;
                        return result;
              } catch (err) {
                        lastError = err instanceof Error ? err : new Error(String(err));
                        this.consecutiveFailures++;

                if (attempt < this.options.maxRetries) {
                            this.onRetry?.(attempt + 1, lastError);
                            const delay = this.calculateBackoff(attempt);
                            await this.sleep(delay);
                }
              }
      }

      throw lastError ?? new Error("Retry failed with unknown error");
  }

  private calculateBackoff(attempt: number): number {
        const exponentialDelay = this.options.baseDelayMs * Math.pow(2, attempt);
        const jitter = exponentialDelay * 0.25 * Math.random();
        return Math.min(exponentialDelay + jitter, this.options.maxDelayMs);
  }

  private sleep(ms: number): Promise<void> {
        return new Promise((resolve) => setTimeout(resolve, ms));
  }

  getFailureCount(): number {
        return this.consecutiveFailures;
  }

  reset(): void {
        this.consecutiveFailures = 0;
  }
}

export async function withRetry<T>(
    fn: () => Promise<T>,
    options?: RetryOptions
  ): Promise<T> {
    const handler = new RetryHandler(options);
    return handler.execute(fn);
}
