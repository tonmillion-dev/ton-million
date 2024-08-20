import * as fs from 'fs';
import * as path from 'path';
import { Address, Cell, contractAddress } from '@ton/core';
import { TonMillion } from "../build/TonMillion/tact_TonMillion";
import { prepareTactDeployment } from "@tact-lang/deployer";
import { TonMillionToken } from '../build/Jetton/tact_TonMillionToken';
import { NetworkProvider } from '@ton/blueprint';
import { TonMillionTokenV1 } from '../build/Jetton/tact_TonMillionTokenV1';
import { buildOnchainMetadata } from './util';

export async function run(provider: NetworkProvider, args: string[]) {
    // Parameters
    let testnet = true;                                 // Flag for testnet or mainnet
    let packageName = 'tact_TonMillionTokenV1.pkg';  // Name of your package to deploy
    let outputPath = path.resolve(__dirname, 'build'); // Path to output directory
    let owner = Address.parse('0QBkifpAX0TuKNK2OzcOilQFx5gyw2CsSnOZSyRap3AJu-aD');

    const jettonParams = {
        name: "Ton Million Token",
        description: "This is description of Test Jetton Token in Tact-lang",
        symbol: "TMT",
        image: "https://avatars.githubusercontent.com/u/104382459?s=200&v=4",
    };

    const content = buildOnchainMetadata(jettonParams);

    let init = await TonMillionTokenV1.init(
        owner,
        content,
        BigInt(100000n)
    );    // Create initial data for our contract

    // Calculations
    let address = contractAddress(0, init);     // Calculate contract address. MUST match with the address in the verifier
    let data = init.data.toBoc();               // Create init data
    let pkg = fs.readFileSync(                  // Read package file
        path.resolve(outputPath, packageName)
    );

    // Prepare deploy
    let link = await prepareTactDeployment({ pkg, data, testnet });

    // Present a deployment link and contract address
    console.log('Address: ' + address.toString({ testOnly: testnet }));
    console.log('Deploy link: ' + link);
}
