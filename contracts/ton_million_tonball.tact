import "@stdlib/deploy";
import "@stdlib/ownable";

struct Map {
    data: map<Int as uint16, Int as uint16>;
}

struct Lottery {
    user: Address;
    data: map<Int as uint16, Int as uint16>;
    claimed: Bool;
}

struct LotteryData {
    n: Int as uint16;
    data: map<Int as uint16, Lottery>;
}

message RoundController_StartRound {

}

message RoundController_EndRound {
    // winningNumbers: map<Int as uint16, Int as uint16>;
    winningNumber: String;
}

message RoundController_Claim {

}

message RoundController_Deposit {
    // numbers: map<Int as uint16, Int as uint16>;
    data: String;
}

message RoundController_CarryOver {
    targetRoundController: Address;
}

message RoundController_Event_Deposit {
    user: Address;
    numbers: map<Int as uint16, Int as uint16>;
}

struct LotteryV2 {
    data: String;
    claimed: Bool;
}

struct LotteryDataV2 {
    user: Address;
    data: map<Int as uint16, LotteryV2>;
    count: Int as uint16;
}

struct AddressBook {
    data: map<Int as uint16, Address>;
    count: Int as uint16;
}

struct Winner {
    data: map<Int as uint16, Address>;
    count: Int as uint16;
}

contract TonBallRoundController with Ownable {
    round: Int;
    roundEnded: Bool;
    adminAddress: Address;
    vault: Address;
    controller: Address;
    depositerCount: Int;
    owner: Address;

    pointDistribution: Int as coins;
    ticketPrice: Int as coins;
    fee: Int as coins;

    // winningNumbers: map<Int as uint16, Int as uint16>;
    winningNumber: String?;
    numberOfWinningNumbers: Int as uint16;
    // lotteryDataByHash: map<Int, LotteryData>;
    // lotteryDataByAddress: map<Address, LotteryData>;

    // lotteryDataByHash: map<Int, String>;
    lotteryData: map<Address, LotteryDataV2>;
    addressBook: map<Int, AddressBook>;

    accumulatedWinnings: Int as coins;
    winners: Winner?;

    init(round: Int,
        adminAddress: Address,
        vault: Address,
        controller: Address,
        numberOfWinningNumbers: Int,
        pointDistribution: Int,
        ticketPrice: Int,
        fee: Int
    ) {
        self.round = round;
        self.roundEnded = false;
        self.owner = sender();
        self.depositerCount = 0;
        self.adminAddress = adminAddress;
        self.vault = vault;
        self.controller = controller;
        self.pointDistribution = pointDistribution;
        self.ticketPrice = ticketPrice;
        self.fee = fee;

        self.numberOfWinningNumbers = numberOfWinningNumbers;
        self.winningNumber = null;

        self.lotteryData = emptyMap();
        self.addressBook = emptyMap();

        self.accumulatedWinnings = 0;
        self.winners = null;
    }

    get fun getWinners(): Winner? {
        require(self.roundEnded, "This round is not ended.");
        require(self.winningNumber != null, "Winning number is not set.");

        let i = 0;
        let hash = self.winningNumber!!.asComment().hash();
        let data = self.addressBook.get(hash);
        if (data == null) {
            return null;
        }

        let winner: Winner = Winner {
            count: data!!.count,
            data: data!!.data,
        };
        return winner;
    }

    receive("identify") {}

    receive(msg: RoundController_EndRound) {
        self.requireOwner();
        self.winningNumber = msg.winningNumber;
        self.roundEnded = true;
        self.accumulatedWinnings = myBalance();

        self.winners = self.getWinners();
    }

    receive(msg: RoundController_Claim) {
        require(self.roundEnded, "This round is not ended.");
        let ctx = context();
        let sender = ctx.sender;

        require(self.winners != null && self.winners!!.count > 0, "No winner is this round.");

        let userData = self.lotteryData.get(sender);
        require(userData != null, "User record is not set.");

        let isUserWinner = self.isUserWin(sender);
        require(isUserWinner > 0, "This user is not a winner.");
        require(self.accumulatedWinnings > 0, "No winning money.");

        let winning = self.accumulatedWinnings / self.winners!!.count;
        let i = 0;
        let claimable = false;

        while (i < userData!!.count) {
            let data = userData!!.data.get(i);
            if (!claimable && data!!.data == self.winningNumber && data!!.claimed == false) {
                let newData = LotteryDataV2{
                    user: userData!!.user,
                    count: userData!!.count,
                    data: userData!!.data,
                };
                newData.data.set(i, LotteryV2{
                    data: data!!.data,
                    claimed: true,
                });
                self.lotteryData.set(sender, newData);
                claimable = true;
            }
            i += 1;
        }

        if (claimable) {
            dump("Claim successfully");
            send(SendParameters{
                to: sender,
                value: self.accumulatedWinnings / self.winners!!.count,
            });
        }
    }

    receive(msg: RoundController_Deposit) {
        let ctx = context();
        let sender = ctx.sender;
        let value = ctx.value;
        require(value >= self.ticketPrice, "Not enough value.");

        let lotteryByAddress = self.lotteryData.get(sender);
        if (lotteryByAddress == null) {
            let newLotteryData = LotteryDataV2 {
                count: 1,
                data: emptyMap(),
                user: sender,
            };
            newLotteryData.data.set(0, LotteryV2{
                data: msg.data,
                claimed: false,
            });
            self.lotteryData.set(sender, newLotteryData);
        } else {
            let newLotteryData = LotteryDataV2 {
                count: lotteryByAddress!!.count,
                data: lotteryByAddress!!.data,
                user: lotteryByAddress!!.user,
            };
            newLotteryData.data.set(newLotteryData.count, LotteryV2 {
                data: msg.data,
                claimed: false,
            });
            newLotteryData.count += 1;
            self.lotteryData.set(sender, newLotteryData);
        }

        let hash = msg.data.asComment().hash();
        let addressBook = self.addressBook.get(hash);
        if (addressBook == null) {
            let newAddressBookData = AddressBook{
                data: emptyMap(),
                count: 1,
            };
            newAddressBookData.data.set(0, sender);
            self.addressBook.set(hash, newAddressBookData);
        } else {
            let newAddressBookData = AddressBook{
                data: addressBook!!.data,
                count: addressBook!!.count + 1
            };
            newAddressBookData.data.set(addressBook!!.count, sender);
            self.addressBook.set(hash, newAddressBookData);
        }

        self.depositerCount += 1;
        send(SendParameters{
            to: self.vault,
            value: self.fee,
        });
    }

    receive() {
        dump("Receive");
    }

    receive(msg: RoundController_CarryOver) {
        self.requireOwner();
        require(self.roundEnded, "Round is not ended.");
        require(self.winners == null, "Winner is exist. Cannot carry out!");
        send(SendParameters {
            to: msg.targetRoundController,
            value: 0,
            mode: SendRemainingBalance | SendIgnoreErrors,
            bounce: true,
        });
    }

    get fun isUserWin(user: Address): Int {
        require(self.roundEnded, "Round is not ended.");
        require(self.winningNumber != null, "Winning numbers are not set.");

        let userRecord = self.lotteryData.get(user);
        require(userRecord != null, "User lottery record is null");

        let i = 0;
        let ret = 0;
        while (i < userRecord!!.count) {
            let lottery = userRecord!!.data.get(i);
            require(lottery != null, "User lottery data is null");
            let data = lottery!!.data;
            if (data == self.winningNumber) {
                ret += 1;
            }
            i += 1;
        }

        return ret;
    }

    get fun numberOfClaimable(user: Address): Int {
        require(self.roundEnded, "Round is not ended.");
        require(self.winningNumber != null, "Winning numbers are not set.");
        require(self.winners != null, "No winner is this round.");

        let i = 0;
        let ret = 0;
        let userRecord = self.lotteryData.get(user);
        require(userRecord != null, "User lottery record is null");

        while (i < userRecord!!.count) {
            let lottery = userRecord!!.data.get(i);
            require(lottery != null, "User lottery data is null");
            let data = lottery!!.data;
            if (data == self.winningNumber && lottery!!.claimed == false) {
                ret += 1;
            }
            i += 1;
        }

        return ret;
    }

    get fun getWinningNumbers(): String? {
        require(self.roundEnded, "Round is not ended.");
        return self.winningNumber;
    }

    get fun getUserNumbers(user: Address, index: Int): String? {
        let item = self.lotteryData.get(user);
        if (item == null) {
            return null;
        }

        let count = item!!.count;
        let data = item!!.data.get(index);
        if (data == null) {
            return null;
        }

        return data!!.data;
    }

    get fun numberOfUserTicket(user: Address): Int? {
        let item = self.lotteryData.get(user);
        if (item == null) {
            return null;
        }

        let data = item!!.count;
        return data;
    }

    get fun getDepositorCount(): Int {
        return self.depositerCount;
    }

    get fun getBalance(): Int {
        return myBalance();
    }

    get fun getWinnings(): Int {
        if (!self.roundEnded) {
            return 0;
        }
        if (self.winners!!.count == 0) {
            return 0;
        }
        return self.accumulatedWinnings / self.winners!!.count;
    }

    get fun isRoundEnded(): Bool {
        return self.roundEnded;
    }

    get fun nOfNumbers(): Int {
        return self.numberOfWinningNumbers;
    }

    get fun getTicketPrice(): Int {
        return self.ticketPrice;
    }

    get fun getFee(): Int {
        return self.fee;
    }
}

//////////
message TonBall_RoundStart {
}

message TonBall_RoundEnd {
    round: Int;
}

message TonBall_SetNumberOfWinningNumbers {
    numberOfWinningNumbers: Int as uint16;
}

message TonBall_CarryOver {
    round: Int as uint16;
}

contract TonBall with Deployable, Ownable {
    const MinTonForStorage: Int = ton("0.01");
    round: Int as uint32;
    roundControllerAddressMap: map<Int, Address>;
    owner: Address;
    vault: Address;
    pointAddress: Address;
    pointDistribution: Int as coins;
    ticketPrice: Int as coins;
    fee: Int as coins;

    numberOfWinningNumbers: Int as uint16;
    maximumWinningNumber: Int as uint16;

    init(vault: Address,
        initialPointAddress: Address,
        pointDistribution: Int,
        ticketPrice: Int,
        fee: Int,
        numberOfWinningNumbers: Int,
        maximumWinningNumber: Int) {
        self.owner = sender();
        self.round = 0;
        self.roundControllerAddressMap = emptyMap();
        self.vault = vault;
        self.pointAddress = initialPointAddress;
        self.pointDistribution = pointDistribution;
        self.ticketPrice = ticketPrice;
        self.fee = fee;
        self.numberOfWinningNumbers = numberOfWinningNumbers;
        self.maximumWinningNumber = maximumWinningNumber;
    }

    receive() {
        dump("Receive");
    }

    receive(msg: TonBall_RoundStart) {
        self.requireOwner();
        self.round += 1;
        let init: StateInit = initOf TonBallRoundController(
            self.round,
            self.owner,
            self.vault,
            myAddress(),
            self.numberOfWinningNumbers,
            self.pointDistribution,
            self.ticketPrice,
            self.fee,
        );
        let address = contractAddress(init);
        send(SendParameters {
           to: address,
            value: ton("0.1"),
            mode: SendIgnoreErrors,
            code: init.code,
            data: init.data,
            bounce: true,
            body: "identify".asComment()
        });
        self.roundControllerAddressMap.set(self.round, address);
    }

    receive(msg: TonBall_RoundEnd) {
        // generate 6 random ints(1~45)
        let index = 0;
        let sb = beginString();
        let cache: Map = Map {
            data: emptyMap()
        };
        while (index < self.numberOfWinningNumbers) {
            let item = random(1, self.maximumWinningNumber);
            if (cache.data.get(item) == null) {
                cache.data.set(item, 1);
                index += 1;
            }
        }

        index = 0;
        let len = 0;
        while (index < self.maximumWinningNumber) {
            let item = cache.data.get(index);
            if (item == 1) {
                sb.append(index.toString());
                if (len < self.numberOfWinningNumbers - 1) {
                    sb.append(",");
                }
                len += 1;
            }
            index += 1;
        }
        let controllerAddress = self.roundControllerAddressMap.get(msg.round);
        require(controllerAddress != null, "Controller is not set.");
        send(SendParameters {
            to: controllerAddress!!,
            value: 0,
            mode: SendRemainingValue | SendIgnoreErrors,
            bounce: true,
            body: RoundController_EndRound {
                winningNumber: sb.toString(),
            }.toCell(),
        });
    }

    receive(msg: TonBall_SetNumberOfWinningNumbers) {
        self.requireOwner();
        self.numberOfWinningNumbers = msg.numberOfWinningNumbers;
    }

    receive(msg: TonBall_CarryOver) {
        self.requireOwner();
        require(msg.round + 1 <= self.round, "Round + 1 must be equal or less than current round");
        let previousRoundController = self.roundControllerAddressMap.get(msg.round);
        let targetRoundController = self.roundControllerAddressMap.get(msg.round + 1);
        require(previousRoundController != null, "Previous round controller is not set.");
        require(targetRoundController != null, "Target round controller is not set.");
        send(SendParameters{
            to: previousRoundController!!,
            value: 0,
            mode: SendRemainingValue | SendIgnoreErrors,
            body: RoundController_CarryOver{
                targetRoundController: targetRoundController!!,
            }.toCell(),
        });
    }

    get fun currentRound(): Int {
        return self.round;
    }

    get fun currentRoundControllerAddress(): Address? {
        return self.roundControllerAddressMap.get(self.round);
    }

    get fun roundControllerAddress(round: Int): Address? {
        return self.roundControllerAddressMap.get(round);
    }
}
