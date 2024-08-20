import * as fs from 'fs';
import * as path from 'path';
import { Address, contractAddress, toNano } from '@ton/core';
import { TonMillion } from "../build/TonMillion/tact_TonMillion";
import { prepareTactDeployment } from "@tact-lang/deployer";
import { NetworkProvider } from '@ton/blueprint';
import { TonMillion_TonOne } from '../build/TonMillion_Tonone/tact_TonMillion_TonOne';

export async function run(provider: NetworkProvider, args: string[]) {
    // Parameters
    let testnet = true;                                 // Flag for testnet or mainnet
    let packageName = 'tact_TonMillion_TonOne.pkg';  // Name of your package to deploy
    let outputPath = path.resolve(__dirname, 'build'); // Path to output directory
    let owner = Address.parse('UQBkifpAX0TuKNK2OzcOilQFx5gyw2CsSnOZSyRap3AJu10J');    // Our sample contract has an owner
    let vault = Address.parse('UQDUFEBPyT0EGjTbtpdYByVOlbDoXzpEj4O3BTkLHrHX9J-e');
    let point = Address.parse('kQCo1spqoKLxpuskFrcxZ8HYzIQsbTmPOQwpATmhlQWs8NS2');
    let init = await TonMillion_TonOne.init(
        vault,
        point,
        toNano("1"),
        toNano("0.05"),
    );

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
