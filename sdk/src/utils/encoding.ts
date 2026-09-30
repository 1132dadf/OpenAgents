/**
 * ABI encoding/decoding utilities for EVM-compatible contract interactions.
 * Contributor: 1132dadf | 2026-09-30 | Windows 11, x86_64
 */

export type AbiType = "uint256" | "address" | "bytes32" | "string" | "bool";

export interface AbiParam {
    type: AbiType;
    value: string | number | bigint | boolean;
}

const MAX_UINT256 = (1n << 256n) - 1n;

export function encodeUint256(value: bigint | number): string {
    const n = BigInt(value);
    if (n < 0n || n > MAX_UINT256) throw new Error("Uint256 overflow");
    return n.toString(16).padStart(64, "0");
}

export function encodeAddress(address: string): string {
    const cleaned = address.startsWith("0x") ? address.slice(2) : address;
    return cleaned.toLowerCase().padStart(64, "0");
}

export function encodeBytes32(data: string): string {
    const cleaned = data.startsWith("0x") ? data.slice(2) : data;
    return cleaned.padEnd(64, "0");
}

export function encodeBool(value: boolean): string {
    return value ? "1".padStart(64, "0") : "0".padStart(64, "0");
}

export function encodeParams(params: AbiParam[]): string {
    let encoded = "0x";
    for (const param of params) {
          switch (param.type) {
            case "uint256":
                      encoded += encodeUint256(BigInt(param.value as number));
                      break;
            case "address":
                      encoded += encodeAddress(param.value as string);
                      break;
            case "bytes32":
                      encoded += encodeBytes32(param.value as string);
                      break;
            case "bool":
                      encoded += encodeBool(param.value as boolean);
                      break;
            case "string":
                      const hexStr = Buffer.from(param.value as string).toString("hex");
                      encoded += hexStr.padEnd(64, "0");
                      break;
          }
    }
    return encoded;
}

export function decodeHex(hex: string): bigint {
    if (!hex.startsWith("0x")) throw new Error("Hex value must start with 0x");
    return BigInt(hex);
}

export function decodeUint256(slot: string): bigint {
    const cleaned = slot.startsWith("0x") ? slot.slice(2) : slot;
    return BigInt("0x" + cleaned.padStart(64, "0"));
}

export function decodeAddress(slot: string): string {
    const raw = slot.slice(-40);
    return "0x" + raw.toLowerCase();
}

export function decodeBool(slot: string): boolean {
    return BigInt("0x" + slot) !== 0n;
}

export function functionSelector(sig: string): string {
    return "0x" + Buffer.from(sig).toString("hex").slice(0, 8);
}
