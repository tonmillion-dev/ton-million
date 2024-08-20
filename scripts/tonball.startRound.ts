import { Address, toNano } from '@ton/core';
import { NetworkProvider } from '@ton/blueprint';
import { TonBall } from '../build/TonMillion_Tonball/tact_TonBall';

export async function run(provider: NetworkProvider, args: string[]) {
    const contract = TonBall.fromAddress(Address.parse("kQCreDBDdezTwEPfciOZeOivzL1a_G3PG-6Kcx1gUY4qHvbG"));
    const newRoundResult = await contract.send(
        provider.provider(contract.address),
        provider.sender(), {
            value: toNano("0.15"),
        }, {
            $$type: 'TonBall_RoundStart',
        });
}
