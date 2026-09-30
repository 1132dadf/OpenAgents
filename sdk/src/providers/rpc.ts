

/**
 * Deploy a smart contract to the chain
 * @param abi Contract ABI
 * @param bytecode Contract creation bytecode
 * @param args Constructor arguments
 * @param confirmations Number of block confirmations to wait for
 * @returns Deployment receipt with address, txHash, gasUsed
 */
public async deployContract(
        abi: any[],
        bytecode: string,
        args: any[] = [],
        confirmations: number = 1
    ): Promise<{
            address: string;
            txHash: string;
            gasUsed: string;
            blockNumber: number;
    }> {
        // Encode constructor args using ABI
        const params = this.abiCoder.encodeParameters(
                    abi.filter(item => item.type === "constructor")[0]?.inputs || [],
                    args
                );
        const data = bytecode + params.slice(2);

    // Send deployment transaction
    const txHash = await this.sendTransaction({
                data: data,
    });

    // Wait for transaction receipt
    let receipt = await this.waitForTransactionReceipt(txHash);

    // Wait for additional confirmations
    if (confirmations > 0) {
                await this.waitForBlock(Number(receipt.blockNumber) + confirmations);
    }

    return {
                address: receipt.contractAddress,
                txHash: txHash,
                gasUsed: receipt.gasUsed,
                blockNumber: Number(receipt.blockNumber),
    };
}
