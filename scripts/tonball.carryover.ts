import { Address, toNano } from '@ton/core';
import { NetworkProvider } from '@ton/blueprint';
import { TonBall } from '../build/TonMillion_Tonball/tact_TonBall';

export async function run(provider: NetworkProvider, args: string[]) {
    const contract = TonBall.fromAddress(Address.parse("kQDG6P-OkEdsbkHjvG1IAITbMbTh972l8nQY2wEzy9Qfgl3J"));
    const newRoundResult = await contract.send(
        provider.provider(contract.address),
        provider.sender(), {
            value: toNano("0.1"),
        }, {
            $$type: 'TonBall_CarryOver',
            round: BigInt(1),
        });
}
