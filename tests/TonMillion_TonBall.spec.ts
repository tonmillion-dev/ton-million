import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { TonBall } from '../build/TonMillion_Tonball/tact_TonBall';
import { TonMillionTokenV1 } from '../build/Jetton/tact_TonMillionTokenV1';
import { Address, Cell, Dictionary, fromNano, toNano } from '@ton/core';
import { Lottery, TonBallRoundController } from '../build/TonMillion_Tonball/tact_TonBallRoundController';

describe("TonMillion_TonBall Test", () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let depositors: SandboxContract<TreasuryContract>[] = [];
    let vault: SandboxContract<TreasuryContract>;
    let tonBall: SandboxContract<TonBall>;
    let pointToken: SandboxContract<TonMillionTokenV1>;

    let nOfDepositors = 100;

    let maxWinningNo = 8;
    let nOfWinningNo = 2;

    beforeEach(async () => {
        blockchain = await Blockchain.create();
        deployer = await blockchain.treasury('deployer');

        console.log('Init depositors...');
        for (let i = 0; i < nOfDepositors; i++) {
            depositors[i] = await blockchain.treasury(`depositor-${i}`);
        }
        console.log('Finish init depositors');

        vault = await blockchain.treasury('vault');
        pointToken = blockchain.openContract(await TonMillionTokenV1.fromInit(
            deployer.address,
            Cell.EMPTY,
            toNano(1_000_000_000)
        ));

        console.log('Init tonBall contract...');
        tonBall = blockchain.openContract(await TonBall.fromInit(
            vault.address,
            pointToken.address,
            toNano(100),
            toNano(1),
            toNano("0.05"),
            BigInt(nOfWinningNo),
            BigInt(maxWinningNo),
        ));
        console.log('Finish init tonBall contract');
    });

    it ('should deploy', async () => {});

    it ('test 1', async () => {
        let round = 1;
        let maxRound = 100;
        let previousWinner: string[] | null = null;
        let nOfWinnings = [];
        for (let i = 0; i < depositors.length; i++) nOfWinnings[i] = 0;
        for (let i = round; i <= maxRound; i++) {
            console.log(`1. Start round ${i}`);
            await tonBall.send(deployer.getSender(), {
                value: toNano("0.15"),
                bounce: true
            }, {
                $$type: "TonBall_RoundStart",
            });

            if (round > 1) {
                console.log(`No winners in previous round, carry over.`);
                const result = await tonBall.send(deployer.getSender(), {
                    value: toNano("0.1"),
                }, {
                    $$type: "TonBall_CarryOver",
                    round: BigInt(round - 1),
                });
            }

            const roundContractAddress = await tonBall.getCurrentRoundControllerAddress();
            console.log('roundContract', roundContractAddress);
            const roundContract = blockchain.openContract(TonBallRoundController.fromAddress(roundContractAddress!));
            for (let j = 0; j < depositors.length; j++) {
                const ranNums = generateRandomNumbers(nOfWinningNo, maxWinningNo);
                const ranNumsStr = ranNums.join(",");
                // console.log(`User ${j}(${depositors[j].address.toString()}): ${map.get(0)} ${map.get(1)} ${map.get(2)} ${map.get(3)} ${map.get(4)} ${map.get(5)}`);
                // console.log(`User ${j} deposit numbers: ${ranNums}`)
                // console.log(ranNumsStr);
                const result = await roundContract.send(depositors[j].getSender(), {
                    value: toNano("1.0"),
                    bounce: true
                }, {
                    $$type: "RoundController_Deposit",
                    data: ranNumsStr,
                });

                //const userNumbers = await roundContract.getGetUserNumbers(depositors[j].address);
                // console.log('userNumbers', userNumbers.get(0));
            }

            console.log(`2. End round ${i}`);
            await tonBall.send(deployer.getSender(), {
                value: toNano("0.1"),
                bounce: true
            }, { $$type: "TonBall_RoundEnd", round: BigInt(i) });


            console.log(`3. What is answer?`);
            const winningNumbers = await roundContract.getGetWinningNumbers();
            console.log('Answer', winningNumbers);
            const winners = await roundContract.getGetWinners();
            console.log('Winner', winners);

            const values = winners?.data.values();
            if (values != null) {
                for (let j = 0; j < depositors.length; j++) {
                    for (let k = 0; k < values.length; k++) {
                        if (depositors[j].address.equals(values[k])) {
                            console.log(`User ${j} claim`);
                            await roundContract.send(depositors[j].getSender(), {
                                value: toNano("0.1")
                            }, {
                                $$type: "RoundController_Claim"
                            });
                        }
                    }
                }
            }

        }
    });

       //     console.log(`2. End round ${i}`);
       //     await tonBall.send(deployer.getSender(), {
       //         value: toNano("0.1"),
       //         bounce: true
       //     }, { $$type: "TonBall_RoundEnd", round: BigInt(round) });
       //
       //     console.log(`3. Get winning numbers`);
       //     const winnings = await roundContract.getGetWinningNumbers();
       //     console.log(winnings);
       //
       //     console.log(`4. Is there any winners?`);
       //     const winnerResult= await roundContract.getGetWinners();
       //     if (winnerResult == null) {
       //       previousWinner = null;
       //     } else if (winnerResult?.n === BigInt(0)) {
       //         previousWinner = null;
       //     } else {
       //         previousWinner = winnerResult?.data.values().map((lottery) => lottery.user.toString());
       //     }
       //     console.log('winner', previousWinner);
       //
       //     if (previousWinner != null) {
       //         for (let k = 0; k < depositors.length; k++) {
       //             if (previousWinner.includes(depositors[k].address.toString())) {
       //                 nOfWinnings[k]++;
       //                 const winnings = await roundContract.getGetWinnings();
       //                 console.log(`User ${k} is answer(address: ${depositors[k].address.toString()}). Claim!, prev balance=${await depositors[k].getBalance()}, will receive=${winnings}`);
       //                 await roundContract.send(depositors[k].getSender(), {
       //                     value: toNano("0.1")
       //                 }, {
       //                    $$type: "RoundController_Claim"
       //                 });
       //
       //                 console.log(`Balance of User ${k}, balance=${await depositors[k].getBalance()}`);
       //
       //                 console.log(`Try reclaim? Must be failed`);
       //                 await roundContract.send(depositors[k].getSender(), {
       //                     value: toNano("0.1")
       //                 }, {
       //                     $$type: "RoundController_Claim"
       //                 });
       //                 console.log(`Balance of User ${k}, balance=${await depositors[k].getBalance()}`);
       //             }
       //         }
       //     }
       //
       //     const money = await roundContract.getGetBalance();
       //     console.log('5. Total betting', money);
       //     round++;
       // }
       //
       // for (let i = 0; i < depositors.length; i++) {
       //     const balance = await depositors[i].getBalance();
       //     console.log(`User ${i}, number of winnings=${nOfWinnings[i]}, balance=${balance}, diff=${balance - BigInt(1000000000000000n)}`);
       // }
    // });

    // it ('test2 (User deposit several times)', async () => {
    //     let round = 1;
    //     let maxRound = 100;
    //     let previousWinner: string[] | null = null;
    //     let nOfWinnings = [];
    //     for (let i = 0; i < depositors.length; i++) nOfWinnings[i] = 0;
    //     for (let i = round; i <= maxRound; i++) {
    //         console.log(`1. Start round ${i}`);
    //         await tonBall.send(deployer.getSender(), {
    //             value: toNano("0.15"),
    //             bounce: true
    //         }, {
    //             $$type: "TonBall_RoundStart",
    //         });
    //
    //         if (round > 1 && previousWinner == null) {
    //             console.log(`No winners in previous round, carry over.`);
    //             const result = await tonBall.send(deployer.getSender(), {
    //                 value: toNano("0.1"),
    //             }, {
    //                 $$type: "TonBall_CarryOver",
    //                 round: BigInt(round - 1),
    //             });
    //         }
    //
    //         const roundContractAddress = await tonBall.getCurrentRoundControllerAddress();
    //         console.log('roundContract', roundContractAddress);
    //         const roundContract = blockchain.openContract(TonBallRoundController.fromAddress(roundContractAddress!));
    //         console.log('Start!');
    //         for (let j = 0; j < depositors.length; j++) {
    //             const ranNums = generateRandomNumbers(nOfWinningNo, maxWinningNo);
    //             const map: Dictionary<number, number> = Dictionary.empty();
    //             ranNums.forEach((rn, index) => map.set(index, rn));
    //             await roundContract.send(depositors[j].getSender(), {
    //                 value: toNano("1.0"),
    //                 bounce: true
    //             }, {
    //                 $$type: "RoundController_Deposit",
    //                 numbers: map,
    //             });
    //             await roundContract.send(depositors[j].getSender(), {
    //                 value: toNano("1.0"),
    //                 bounce: true
    //             }, {
    //                 $$type: "RoundController_Deposit",
    //                 numbers: map,
    //             });
    //             await roundContract.send(depositors[j].getSender(), {
    //                 value: toNano("1.0"),
    //                 bounce: true
    //             }, {
    //                 $$type: "RoundController_Deposit",
    //                 numbers: map,
    //             });
    //             const userNumbers = await roundContract.getGetUserNumbers(depositors[j].address);
    //             // console.log('userNumbers', userNumbers.get(0));
    //         }
    //
    //         console.log(`2. End round ${i}`);
    //         await tonBall.send(deployer.getSender(), {
    //             value: toNano("0.1"),
    //             bounce: true
    //         }, { $$type: "TonBall_RoundEnd", round: BigInt(round) });
    //
    //         console.log(`3. Get winning numbers`);
    //         const winnings = await roundContract.getGetWinningNumbers();
    //         console.log(winnings);
    //
    //         console.log(`4. Is there any winners?`);
    //         const winnerResult= await roundContract.getGetWinners();
    //         if (winnerResult == null) {
    //             previousWinner = null;
    //         } else if (winnerResult?.n === BigInt(0)) {
    //             previousWinner = null;
    //         } else {
    //             previousWinner = winnerResult?.data.values().map((lottery) => lottery.user.toString());
    //         }
    //         console.log('winner', previousWinner);
    //
    //         if (previousWinner != null) {
    //             for (let k = 0; k < depositors.length; k++) {
    //                 const isUserWin = await roundContract.getIsUserWin(depositors[k].address);
    //                 console.log(`Is user ${k} is win? ${isUserWin}`);
    //                 if (previousWinner.includes(depositors[k].address.toString())) {
    //                     const nOfWin = await roundContract.getNumberOfWins(depositors[k].address);
    //                     console.log(`The number of user win: ${nOfWin}`);
    //                     let balance1 = BigInt(0);
    //                     let balance2 = BigInt(0);
    //                     let balance3 = BigInt(0);
    //                     let balance4 = BigInt(0);
    //                     nOfWinnings[k]++;
    //                     const winnings = await roundContract.getGetWinnings();
    //                     console.log(`User ${k} is answer(address: ${depositors[k].address.toString()}). Claim!, prev balance=${await depositors[k].getBalance()}, will receive=${winnings}`);
    //                     const usersNumber = await roundContract.getGetUserNumbers(depositors[k].address);
    //                     const lotteries = usersNumber.values();
    //                     const arr = lotteries.map((l) => l.data);
    //                     balance1 = await depositors[k].getBalance();
    //                     console.log(`User ${k}'s number: ${arr}`)
    //                     await roundContract.send(depositors[k].getSender(), {
    //                         value: toNano("0.1")
    //                     }, {
    //                         $$type: "RoundController_Claim"
    //                     });
    //
    //                     console.log(`Can claim: ${Number(await roundContract.getNumberOfClaimable(depositors[k].address))}`);
    //
    //                     console.log(`Balance of User ${k}, balance=${await depositors[k].getBalance()}`);
    //                     console.log(`Try reclaim? Must be successful`);
    //                     await roundContract.send(depositors[k].getSender(), {
    //                         value: toNano("0.1")
    //                     }, {
    //                         $$type: "RoundController_Claim"
    //                     });
    //
    //                     console.log(`Can claim: ${Number(await roundContract.getNumberOfClaimable(depositors[k].address))}`);
    //                     console.log(`Balance of User ${k}, balance=${await depositors[k].getBalance()}`);
    //                     balance2 = await depositors[k].getBalance();
    //
    //                     console.log(`Try reclaim? Must be successful`);
    //                     await roundContract.send(depositors[k].getSender(), {
    //                         value: toNano("0.1")
    //                     }, {
    //                         $$type: "RoundController_Claim"
    //                     });
    //
    //                     console.log(`Can claim: ${Number(await roundContract.getNumberOfClaimable(depositors[k].address))}`);
    //                     console.log(`Balance of User ${k}, balance=${await depositors[k].getBalance()}`);
    //                     balance3 = await depositors[k].getBalance();
    //
    //                     console.log(`Try reclaim? Must be failed`);
    //                     await roundContract.send(depositors[k].getSender(), {
    //                         value: toNano("0.1")
    //                     }, {
    //                         $$type: "RoundController_Claim"
    //                     });
    //
    //                     console.log(`Can claim: ${Number(await roundContract.getNumberOfClaimable(depositors[k].address))}`);
    //                     console.log(`Balance of User ${k}, balance=${await depositors[k].getBalance()}`);
    //                     balance4 = await depositors[k].getBalance();
    //
    //                     console.log(`User ${k} balance: ${balance1} -> ${balance2} -> ${balance3} -> ${balance4}`);
    //                 } else {
    //                     console.log(`If user is not a winner, try claim?`);
    //                     let balance1 = BigInt(0);
    //                     balance1 = await depositors[k].getBalance();
    //                     await roundContract.send(depositors[k].getSender(), {
    //                         value: toNano("0.1")
    //                     }, {
    //                         $$type: "RoundController_Claim"
    //                     });
    //
    //                     let balance2 = BigInt(0);
    //                     balance2 = await depositors[k].getBalance();
    //                     console.log(`[Not winner] User ${k} balance: ${balance1} -> ${balance2}`);
    //                 }
    //             }
    //         }
    //
    //         const money = await roundContract.getGetBalance();
    //         console.log('5. Total betting', money);
    //         round++;
    //     }
    //
    //     for (let i = 0; i < depositors.length; i++) {
    //         const balance = await depositors[i].getBalance();
    //         console.log(`User ${i}, number of winnings=${nOfWinnings[i]}, balance=${balance}, diff=${balance - BigInt(1000000000000000n)}`);
    //     }
    // });
});

function generateRandomNumbers(length: number, maxNum: number) {
    let arr = [];
    while (arr.length < length) {
        const r = Math.floor((Math.random() * 100) % maxNum) + 1;
        if (arr.indexOf(r) === -1) arr.push(r);
    }
    arr = arr.sort((a, b) => {
        if (a < b) return -1;
        else if (a === b) return 0;
        else return 1;
    })
    return arr;
}
