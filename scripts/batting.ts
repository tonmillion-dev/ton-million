import * as fs from 'fs';
import * as path from 'path';
import { Address, contractAddress, toNano } from '@ton/core';
import { TonMillion } from "../build/TonMillion/tact_TonMillion";
import { prepareTactDeployment } from "@tact-lang/deployer";
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider, args: string[]) {
    // Parameters
    let testnet = true;                                 // Flag for testnet or mainnet
    let packageName = 'tact_TonMillion.pkg';  // Name of your package to deploy
    let outputPath = path.resolve(__dirname, 'build'); // Path to output directory
    let owner = Address.parse('UQBkifpAX0TuKNK2OzcOilQFx5gyw2CsSnOZSyRap3AJu10J');    // Our sample contract has an owner
    let vault = Address.parse('UQDUFEBPyT0EGjTbtpdYByVOlbDoXzpEj4O3BTkLHrHX9J-e');
    let init = await TonMillion.init(vault);    // Create initial data for our contract

    const contract = TonMillion.fromAddress(Address.parse("EQBAV65AyQ-8Zn9RHHXhU_q_MH36wtQCGv4_71A8GxukGvc2"))
    const battingResult = await contract.send(
        provider.provider(contract.address),
        provider.sender(), {
            value: toNano("1.1"),
        },
        {
            $$type: 'Deposit',
            round: BigInt(1),
            flag: BigInt(1)
        }
    )

}
