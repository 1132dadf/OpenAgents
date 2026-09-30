import { generateKeyPair, signMessage, keccak256 } from "../utils/crypto";
import { encodeParams, AbiParam } from "../utils/encoding";
import { RpcProvider } from "../providers/rpc";

// Contributor: 1132dadf | 2026-09-30 | Windows 11, x86_64

export interface WalletConfig {
    privateKey?: string;
    provider: RpcProvider;
}

export interface Transaction {
    to: string;
    value: bigint;
    data: string;
    gasLimit: bigint;
    gasPrice?: bigint;
    nonce?: number;
    chainId?: number;
}

export interface SignedTransaction {
    raw: string;
    hash: string;
}

export class Wallet {
    public readonly address: string;
    private provider: RpcProvider;
    private getSigningKey: () => string;

  constructor(config: WalletConfig) {
        let privateKey: string;
        if (config.privateKey) {
                privateKey = config.privateKey;
        } else {
                const keyPair = generateKeyPair();
                privateKey = keyPair.privateKey;
        }
        this.address = this.deriveAddress(privateKey);
        this.provider = config.provider;
        this.getSigningKey = () => privateKey;
  }

  private deriveAddress(privateKey: string): string {
        const { ec as EC } = require("elliptic");
        const curve = new EC("secp256k1");
        const key = curve.keyFromPrivate(privateKey, "hex");
        const pubKey = key.getPublic(false, "hex").slice(2);
        const hash = keccak256(Buffer.from(pubKey, "hex"));
        return "0x" + hash.slice(-40);
  }

  async signTransaction(tx: Transaction): Promise<SignedTransaction> {
        const providerChainId = Number(await this.provider.call("eth_chainId") as string);
        if (tx.chainId && tx.chainId !== providerChainId) {
                throw new Error("Chain ID mismatch");
        }

      const nonce = tx.nonce ?? await this.getFreshNonce();
        const gasPrice = tx.gasPrice ?? BigInt(await this.provider.call("eth_gasPrice") as string);

      const txData = encodeParams([
        { type: "uint256", value: nonce } as AbiParam,
        { type: "uint256", value: gasPrice } as AbiParam,
        { type: "uint256", value: tx.gasLimit } as AbiParam,
        { type: "address", value: tx.to } as AbiParam,
        { type: "uint256", value: tx.value } as AbiParam,
            ]);

      const txHash = keccak256(txData);
        const key = this.getSigningKey();
        const signature = signMessage(key, txHash);

      return {
              raw: "0x" + txData.slice(2) + signature,
              hash: txHash,
      };
  }

  private async getFreshNonce(): Promise<number> {
        const nonceHex = await this.provider.call("eth_getTransactionCount", [this.address, "latest"]) as string;
        return parseInt(nonceHex, 16);
  }
}
