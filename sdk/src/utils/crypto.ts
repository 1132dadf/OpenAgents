import { createHash, createHmac, randomBytes } from "crypto";
import { ec as EC } from "elliptic";

// Contributor: 1132dadf | 2026-09-30 | Windows 11, x86_64

export function keccak256(data: Buffer): string {
    return createHash("sha3-256").update(data).digest("hex");
}

export function generateKeyPair() {
    const curve = new EC("secp256k1");
    const key = curve.genKeyPair();
    return {
          privateKey: key.getPrivate("hex"),
          publicKey: key.getPublic(false, "hex"),
    };
}

export function signMessage(privateKey: string, messageHash: string): string {
    const curve = new EC("secp256k1");
    const key = curve.keyFromPrivate(privateKey, "hex");
    const sig = key.sign(Buffer.from(messageHash, "hex"));
    return sig.toDER("hex");
}
