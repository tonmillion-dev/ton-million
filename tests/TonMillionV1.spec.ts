import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { Address, toNano } from '@ton/core';
import { TonMillion } from '../wrappers/TonMillion';
import '@ton/test-utils';
import { RoundController } from '../build/TonMillion/tact_RoundController';

describe('TonMillion', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let depositor: SandboxContract<TreasuryContract>;
    let vault: SandboxContract<TreasuryContract>;
    let tonMillion: SandboxContract<TonMillion>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();
        vault = await blockchain.treasury('vault');

        tonMillion = blockchain.openContract(await TonMillion.fromInit(vault.address, BigInt(0)));

        deployer = await blockchain.treasury('deployer');
        depositor = await blockchain.treasury('depositor1');

        // const deployResult = await tonMillion.send(
        //     deployer.getSender(),
        //     {
        //         value: toNano('0.05'),
        //     },
        //     {
        //         $$type: 'Deploy',
        //         queryId: 0n,
        //     }
        // );
        //
        // expect(deployResult.transactions).toHaveTransaction({
        //     from: deployer.address,
        //     to: tonMillion.address,
        //     deploy: true,
        //     success: true,
        // });
    });

    it('should deploy', async () => {
        // the check is done inside beforeEach
        // blockchain and tonMillion are ready to use
    });

    it('parse', () => {
        // const addr = Address.parse("0:894da1eaef3fdd2af2bc26143f4f17c167e818d7ef8af06bf6766537269f7e72z");
        const addr = Address.parse("0:6489fa405f44ee28d2b63b370e8a5405c79832c360ac4a73994b245aa77009bb");
        console.log(addr);
        console.log(addr.toString({ testOnly: true, bounceable: false }));
    })

    it('random test', async () => {
        // const wantToRound = Math.floor((Math.random() * 1000) % 50);
        const round = 100;
        const player = 50;
        const answerCount = [];
        for (let i =0; i <= player; i++) {
            answerCount[i] = 0;
        }

        console.log(`### Start round: 1 ###`);
        const result = await tonMillion.send(
            deployer.getSender(),
            {
                value: toNano("0.2"),
            },
            {
                $$type: 'NewRound'
            }
        );
        console.log(result.events);

        // console.log(result.transactions);

        for (let i = 1; i <= round; i++) {
            const roundContractAddress = await tonMillion.getRoundContract(BigInt(i));
            console.log(`Round-${i} contract address: ${roundContractAddress}`);
            const roundContract = blockchain.openContract(RoundController.fromAddress(roundContractAddress!));
            console.log(`Round-${i} contract balance: ${await roundContract.getBalance()}`);

            for (let j = 1; j <= player; j++) {
                console.log(`## Deposit user-${j}, deposit! ##`);
                depositor = await blockchain.treasury('ton_depositor' + j);

                const depositResult = await roundContract.send(
                    depositor.getSender(),
                    {
                        value: toNano("0.1"),
                        bounce: true,
                    },
                    {
                        $$type: "RequestDeposit",
                        user: depositor.address,
                    });

                console.log(`Round-${i} user-${j} balance: ${await depositor.getBalance()}`);
            }

            console.log(`### Finish Round ${i} ###`);
            const newRoundResult = await tonMillion.send(deployer.getSender(), {
                value: toNano("0.1"),
            }, {
                $$type: "NewRound"
            });
            const endRoundResult = await tonMillion.send(deployer.getSender(), {
                value: toNano("0.1")
            }, {
                $$type: "EndRound",
                round: BigInt(i)
            });

            console.log(newRoundResult.events);

            const answer = await roundContract.getAnswer();
            console.log(`Round ${i} answer=${answer}`);
            // console.log(`ROUND ${i} winnings: ${winning}, flag1=${await roundContract.getTotalFlag1()}, flag2=${await roundContract.getTotalFlag2()}, answer=${await roundContract.getGetAnswer()}`);
            for (let j=1; j<=player; j++) {
                depositor = await blockchain.treasury('ton_depositor' + j);
                if (await roundContract.getIsAnswer(depositor.address)) {
                    console.log(`Depositor ${j}: I am winner!, Get ${await roundContract.getTotalBettingMoney()}, prevBalance=${await depositor.getBalance()}`);
                    answerCount[j]++;
                    await roundContract.send(depositor.getSender(), {
                        value: toNano("0.05")
                    }, {
                        $$type: "RequestClaim",
                        user: depositor.address,
                    });
                    console.log(`Depositor ${j}: Claimed!, Get ${await roundContract.getTotalBettingMoney()}, nextBalance=${await depositor.getBalance()}`);
                }
            }


        }
        // 192307692
        // 50000000

        for (let i=1; i <= player; i++) {
            depositor = await blockchain.treasury('ton_depositor' + i);
            console.log(`player-${i} answer count: ${answerCount[i]},
            balance=${await depositor.getBalance()},
            diff=${await depositor.getBalance() - BigInt(1000000000000000)}`);
        }
        console.log(`vault balance: ${await vault.getBalance()}`);
    });
});

/*

1000000000000000n -> 999998947695600n -> 999999935231999n

1000000000000000n -> 999998947695600n -> 999998935755599n
 */
