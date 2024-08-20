import "@stdlib/deploy";
import "@stdlib/ownable";

// RoundControllerMessage
message RequestDeposit {
    user: Address;
    flag: Int;
}

message RequestClaim {
    round: Int;
    user: Address;
}

message RoundEnd {
    flag: Int;
}

message RoundStart {
    round: Int;
}

// TonMillion Message
message NewRound {

}

message Deposit {
    round: Int;
    flag: Int;
}

message Claim {
    round: Int;
}

message EndRound {
    round: Int;
}

struct Lottery {
    flag: Int;
    isClaimed: Bool;
}

message NewRoundEvent {
    round: Int;
    controllerAddress: Address;
}

message EndRoundEvent {
    round: Int;
    controllerAddress: Address;
}

contract RoundController with Deployable, Ownable {
    round: Int;
    answer: Int;
    roundEnded: Bool;
    lotteryData: map<Address, Lottery>;
    adminAddress: Address;
    depositerCount: Int;
    flag1Count: Int;
    flag2Count: Int;
    totalBatting: Int;
    owner: Address;
    vault: Address;
    controller: Address;
    version: Int;

    init(round: Int, adminAddress: Address, vault: Address, version: Int, controller: Address) {
        self.round = round;
        self.answer = -1;
        self.adminAddress = adminAddress;
        self.lotteryData = emptyMap();
        self.roundEnded = false;
        self.owner = sender();
        self.depositerCount = 0;
        self.flag1Count = 0;
        self.flag2Count = 0;
        self.totalBatting = 0;
        self.vault = vault;
        self.version = version;
        self.controller = controller;
        dump("init");
    }

    // deposit with flag
    receive(msg: RequestDeposit) {
        require(!self.roundEnded, "Round is ended");
        require(msg.user == sender(), "You are not user");
        self.deposit(msg.user, msg.flag);
        send(SendParameters{
            to: self.vault,
            value: ton("0.005"),
            bounce: true,
        });
    }

    receive(msg: RequestClaim) {
        require(self.roundEnded, "Round is not ended");
        self.claim(msg.user);
    }

    receive(msg: RoundEnd) {
        self.requireOwner();
        self.roundEnded = true;
        self.answer = msg.flag;
    }

    receive("identify") {}

    receive(msg: RoundStart) {
        dump("RoundStart");
    }

    fun deposit(user: Address, flag: Int) {
        let data = self.lotteryData.get(user);
        require(data == null, "Already depositted user");
        self.lotteryData.set(user, Lottery{ flag: flag, isClaimed: false });
        self.depositerCount += 1;
        if (flag == 1) { self.flag1Count += 1; }
        else if (flag == 2) { self.flag2Count += 1; }
        self.totalBatting += context().value;
    }

    fun claim(user: Address) {
        require(self.roundEnded, "Round is not ended");
        let data: Lottery? = self.lotteryData.get(user);
        require(data != null, "No deposit data");
        require(self.answer == data!!.flag, "Wrong answer");

        let contractBalance = self.totalBatting;
        let answerCount = 10000000000;
        if (self.answer == 1) {
            answerCount = self.flag1Count;
        } else if (self.answer == 2) {
            answerCount = self.flag2Count;
        } else {
            throw(123);
        }

        let my = contractBalance / answerCount;
        self.lotteryData.set(user, Lottery{
            flag: data!!.flag,
            isClaimed: true,
        });

        send(SendParameters{
            to: user,
            bounce: true,
            value: my,
        });
        send(SendParameters{
            to: user,
            bounce: true,
            value: 0,
            mode: SendRemainingValue | SendIgnoreErrors
        });
    }

    get fun balance(): Int {
        return myBalance();
    }

    get fun lottery(user: Address): Int {
        let data = self.lotteryData.get(user);
        require(data != null, "No Data");
        return data!!.flag;
    }

    get fun isClaimed(user: Address): Bool {
        let data = self.lotteryData.get(user);
        require(data != null, "No Data");
        return data!!.isClaimed;
    }

    get fun totalDepositor(): Int {
        return self.depositerCount;
    }

    get fun totalFlag1(): Int {
        return self.flag1Count;
    }

    get fun totalFlag2(): Int {
        return self.flag2Count;
    }

    get fun totalBattingMoney(): Int {
        return self.totalBatting;
    }

    get fun winnings(): Int {
        if (!self.roundEnded) {
            return 0;
        }

        let contractBalance = self.totalBatting;
        let answerCount = 100000000000;
        if (self.answer == 1) {
            answerCount = self.flag1Count;
        } else if (self.answer == 2) {
            answerCount = self.flag2Count;
        } else {
            throw(123);
        }
        return contractBalance / answerCount;
    }

    get fun isAnswer(user: Address): Bool {
        require(self.roundEnded, "Round is not ended");
        let data = self.lotteryData.get(user);
        if (data == null) {
            return false;
        }
        return data!!.flag == self.answer;
    }

    get fun isRoundEnded(): Bool {
        return self.roundEnded;
    }

    get fun getAnswer(): Int {
        return self.answer;
    }
}

contract TonMillion with Deployable, Ownable {
    const MinTonForStorage: Int = ton("0.01");
    round: Int as uint32;
    roundControllerAddressMap: map<Int, Address>;
    owner: Address;
    vault: Address;
    version: Int;

    init(vault: Address, version: Int) {
        self.owner = sender();
        self.round = 0;
        self.roundControllerAddressMap = emptyMap();
        self.vault = vault;
        self.version = version;
    }

    receive(msg: NewRound) {
        self.requireOwner();
        self.round = self.round + 1;
        let init: StateInit = initOf RoundController(self.round, self.owner, self.vault, self.version, myAddress());
        let address = contractAddress(init);
        send(SendParameters{
            to: address,
            value: ton("0.1"),
            mode: SendIgnoreErrors,
            code: init.code,
            data: init.data,
            bounce: true,
            body: RoundStart{round: self.round}.toCell()
        });
        self.roundControllerAddressMap.set(self.round, address);
        dump("NewRound");
    }

    receive("withdraw") {
        self.requireOwner();
        send(SendParameters{
            to: self.owner,
            value: myBalance() - context().value - self.MinTonForStorage,
            bounce: true,
            mode: SendRemainingValue + SendIgnoreErrors
        });
    }

    receive(msg: EndRound) {
        self.requireOwner();
        let controller = self.roundControllerAddressMap.get(msg.round);
        require(controller != null, "RoundController is null");
        send(SendParameters {
            to: controller!!,
            value: ton("0.05"),
            bounce: true,
            body: RoundEnd{flag: random(1, 3)}.toCell()
        });
        dump("EndRound");
    }

    receive(msg: Claim) {
        self.claim(msg.round, sender());
        send(SendParameters{
            to: sender(),
            value: 0,
            mode: SendPayGasSeparately
        });
    }

    fun claim(round: Int, user: Address) {
        require(sender() == user, "You are not a user");
        let roundControllerAddress = self.roundControllerAddressMap.get(round);
        require(roundControllerAddress != null, "RoundController is not set.");
        send(SendParameters{
            to: roundControllerAddress!!,
            value: 0,
            mode: SendRemainingValue,
            bounce: true,
            body: RequestClaim{ round: round, user: user }.toCell()
        });
    }

    get fun round(): Int {
        return self.round;
    }

    get fun roundContract(round: Int): Address? {
        return self.roundControllerAddressMap.get(round);
    }

    get fun getOwner(): Address {
        return self.owner;
    }
}
