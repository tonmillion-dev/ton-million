import { Address, toNano } from '@ton/core';
import { NetworkProvider } from '@ton/blueprint';
import { TonMillion_TonOne } from '../build/TonMillion_Tonone/tact_TonMillion_TonOne';

export async function run(provider: NetworkProvider, args: string[]) {
    const contract = TonMillion_TonOne.fromAddress(Address.parse("kQBka4oBt5C1Qq-tLkTkRGDavnvUSc5FHleDX-M_qxjAK3v9"));
    await contract.send(
        provider.provider(contract.address),
        provider.sender(), {
        value: toNano("0.1"),
    }, {
        $$type: 'TonMillion_TonOne_NewRound'
    });
}
