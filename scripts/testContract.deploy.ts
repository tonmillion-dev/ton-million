import * as fs from 'fs';
import * as path from 'path';
import { Address, contractAddress, toNano } from '@ton/core';
import { TonMillion } from "../build/TonMillion/tact_TonMillion";
import { prepareTactDeployment } from "@tact-lang/deployer";
import { NetworkProvider } from '@ton/blueprint';
import { TonBall } from '../build/TonMillion_Tonball/tact_TonBall';
import { Test_Contract } from '../build/TestContract/tact_Test_Contract';

export async function run(provider: NetworkProvider, args: string[]) {
    // Parameters
    let testnet = true;                                 // Flag for testnet or mainnet
    let packageName = 'tact_Test_Contract.pkg';  // Name of your package to deploy
    let outputPath = path.resolve(__dirname, 'build'); // Path to output directory
    let init = await Test_Contract.init();

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
