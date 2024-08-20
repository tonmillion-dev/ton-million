import * as fs from 'fs';
import * as path from 'path';
import { Address, Cell, contractAddress, toNano } from '@ton/core';
import { TonMillion } from "../build/TonMillion/tact_TonMillion";
import { prepareTactDeployment } from "@tact-lang/deployer";
import { TonMillionToken } from '../build/Jetton/tact_TonMillionToken';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider, args: string[]) {
    // Parameters
    let testnet = true;                                 // Flag for testnet or mainnet
    let packageName = 'tact_TonMillionToken.pkg';  // Name of your package to deploy
    let outputPath = path.resolve(__dirname, 'build'); // Path to output directory
    let owner = Address.parse('UQBkifpAX0TuKNK2OzcOilQFx5gyw2CsSnOZSyRap3AJu10J');    // Our sample contract has an owner



    const contract = TonMillionToken.fromAddress(Address.parse("kQCVkq1H9uiTYt_uE6scPnjtY2dLJsrRqEaft2VFvYlTAmSw"));
    await contract.send(
        provider.provider(contract.address),
        provider.sender(),
        {
            value: toNano("0.1"),
        }, {
            $$type: 'Minter',
            address: Address.parse('kQCOG7RuqDnTuefjGCgBeC24TTEzr_O1ksT77wMu7CP41o15')
        }
    );
}
