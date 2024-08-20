import "@stdlib/deploy";
import "@stdlib/ownable";

// RoundControllerMessage
message TonMillion_TonOne_RoundController_RequestDeposit {
    user: Address;
}

message TonMillion_TonOne_RoundController_RequestClaim {
    user: Address;
}

message TonMillion_TonOne_RoundController_RoundEnd {
    flag: Int;
}

message TonMillion_TonOne_RoundController_RoundStart {
    round: Int;
}

struct TonMillion_TonOne_RoundController_LotteryData {
    count: Int as int64;
    item: map<Int, Int>;
}

contract TonMillion_TonOne_RoundController with Deployable, Ownable {
    round: Int;
    answer: Int;
    roundEnded: Bool;
    lotteryData: map<Int, Address>;
    lotteryDataByAddress: map<Address, TonMillion_TonOne_RoundController_LotteryData>;
    adminAddress: Address;
    depositerCount: Int;
    totalBetting: Int;
    owner: Address;
    vault: Address;
    controller: Address;
    claimed: Bool;

    // pointDistribution: Int as coins;
    ticketPrice: Int as coins;
    fee: Int as coins;

    init(round: Int,
        adminAddress: Address,
        vault: Address,
        controller: Address,
        // pointDistribution: Int,
        ticketPrice: Int,
        fee: Int) {
        self.round = round;
        self.answer = -1;
        self.adminAddress = adminAddress;
        self.lotteryData = emptyMap();
        self.lotteryDataByAddress = emptyMap();
        self.roundEnded = false;
        self.owner = sender();
        self.depositerCount = 0;
        self.totalBetting = 0;
        self.vault = vault;
        self.controller = controller;
        self.claimed = false;
        // self.pointDistribution = pointDistribution;
        self.ticketPrice = ticketPrice;
        self.fee = fee;
    }

    // deposit with flag
    receive(msg: TonMillion_TonOne_RoundController_RequestDeposit) {
        require(!self.roundEnded, "Round is ended");
        require(msg.user == sender(), "You are not user");
        require(context().value >= self.ticketPrice, "Not enough value.");
        self.deposit(msg.user);
        send(SendParameters{
            to: self.vault,
            // value: ton("0.05"),
            value: self.fee,
            bounce: true,
        });
    }

    receive(msg: TonMillion_TonOne_RoundController_RequestClaim) {
        require(self.roundEnded, "Round is not ended");
        self.claim(msg.user);
    }

    receive(msg: TonMillion_TonOne_RoundController_RoundEnd) {
        self.requireOwner();
        self.roundEnded = true;
        self.answer = random(1, self.depositerCount);
    }

    receive("identify") {}

    receive(msg: TonMillion_TonOne_RoundController_RoundStart) {
        dump("RoundStart");
    }

    fun deposit(user: Address) {
        self.depositerCount += 1;
        self.lotteryData.set(self.depositerCount, user);
        let lotteryItem: TonMillion_TonOne_RoundController_LotteryData? = self.lotteryDataByAddress.get(user);
        if (lotteryItem == null) {
            let array: map<Int, Int> = emptyMap();
            array.set(0, self.depositerCount);
            let newItem = TonMillion_TonOne_RoundController_LotteryData{
                count: 1,
                item: array
            };
            self.lotteryDataByAddress.set(user, newItem);
        } else {
            let count = lotteryItem!!.count + 1;
            let mapItem: map<Int, Int> = lotteryItem!!.item;
            mapItem.set(count, self.depositerCount);
            let newItem = TonMillion_TonOne_RoundController_LotteryData{
                count: count,
                item: mapItem,
            };
            self.lotteryDataByAddress.set(user, newItem);
        }
        self.totalBetting += context().value;
//        send(SendParameters{
//            to: self.controller,
//            value: ton("0.05"),
//            body: TonMillion_TonOne_RoundController_MintPointToken{user: user, amount: self.pointDistribution}.toCell(),
//        });
    }

    fun claim(user: Address) {
        require(self.roundEnded, "Round is not ended");
        let isAnswer = self.isAnswer(user);
        require(isAnswer, "You are not answer");
        self.claimed = true;
        send(SendParameters{
            to: user,
            bounce: true,
            mode: SendRemainingBalance | SendIgnoreErrors,
            value: self.totalBetting,
        });
    }

    get fun balance(): Int {
        return myBalance();
    }

    get fun claimed(): Bool {
        return self.claimed;
    }

    get fun totalDepositor(): Int {
        return self.depositerCount;
    }

    get fun totalBettingMoney(): Int {
        return self.totalBetting;
    }

    get fun isAnswer(user: Address): Bool {
        require(self.roundEnded, "Round is not ended");
        let data = self.lotteryData.get(self.answer);
        if (data == user) {
            return true;
        }

        return false;
    }

    get fun isRoundEnded(): Bool {
        return self.roundEnded;
    }

    get fun userSeed(user: Address): map<Int, Int> {
        let item = self.lotteryDataByAddress.get(user);
        if (item == null) {
            return emptyMap();
        }

        return item!!.item;
    }

    get fun answer(): Int {
        require(self.roundEnded, "Round is not ended");
        return self.answer;
    }

    get fun winner(): Address? {
        require(self.roundEnded, "Round is not ended");
        return self.lotteryData.get(self.answer);
    }
}

// TonMillion Message
message TonMillion_TonOne_NewRound {

}

message TonMillion_TonOne_Deposit {
    round: Int;
    flag: Int;
}

message TonMillion_TonOne_Claim {
    round: Int;
}

message TonMillion_TonOne_EndRound {
    round: Int;
}

struct TonMillion_TonOne_Lottery {
    flag: Int;
    isClaimed: Bool;
}

message TonMillion_TonOne_NewRoundEvent {
    round: Int;
    controllerAddress: Address;
}

message TonMillion_TonOne_EndRoundEvent {
    round: Int;
    controllerAddress: Address;
}

message TonMillion_TonOne_SetPointTokenAddress {
    address: Address;
}

message TonMillion_TonOne_MintPointToken {
    user: Address;
    amount: Int as coins;
}

message TonMillion_TonOne_Mint {
    amount: Int;
    receiver: Address;
}

message TonMillion_TonOne_RoundValue {
    round: Int;
}

message TonMillion_TonOne_SetTicketPrice {
    ticketPrice: Int as coins;
}

message TonMillion_TonOne_SetPointDistribution {
    pointDistribution: Int as coins;
}

message TonMillion_TonOne_SetFee {
    fee: Int as coins;
}

contract TonMillion_TonOne with Deployable, Ownable {
    const MinTonForStorage: Int = ton("0.01");
    round: Int as uint32;
    roundControllerAddressMap: map<Int, Address>;
    owner: Address;
    vault: Address;

    pointAddress: Address;

    // pointDistribution: Int as coins;
    ticketPrice: Int as coins;
    fee: Int as coins;

    init(vault: Address,
        initialPointAddress: Address,
        //pointDistribution: Int,
        ticketPrice: Int,
        fee: Int) {
        self.owner = sender();
        self.round = 0;
        self.roundControllerAddressMap = emptyMap();
        self.vault = vault;
        self.pointAddress = initialPointAddress;
        // self.pointDistribution = pointDistribution;
        self.ticketPrice = ticketPrice;
        self.fee = fee;
    }

//    receive(msg: TonMillion_TonOne_SetPointDistribution) {
//        self.requireOwner();
//        self.pointDistribution = msg.pointDistribution;
//    }

    receive(msg: TonMillion_TonOne_SetTicketPrice) {
        self.requireOwner();
        self.ticketPrice = msg.ticketPrice;
    }

    receive(msg: TonMillion_TonOne_SetFee) {
        self.requireOwner();
        self.fee = msg.fee;
    }

//    receive(msg: TonMillion_TonOne_MintPointToken) {
//        let ctx = context();
//        require(self.roundControllerAddressMap.get(self.round) == ctx.sender, "Invalid sender. Sender must be current round controller contract");
//        send(SendParameters{
//            to: self.pointAddress,
//            value: 0,
//            mode: SendRemainingValue | SendIgnoreErrors,
//            body: Mint{amount: msg.amount, receiver: msg.user}.toCell(),
//        });
//    }

    receive(msg: TonMillion_TonOne_SetPointTokenAddress) {
        self.requireOwner();
        self.pointAddress = msg.address;
    }

    receive(msg: TonMillion_TonOne_NewRound) {
        self.requireOwner();
        self.round = self.round + 1;
        let init: StateInit = initOf TonMillion_TonOne_RoundController(
            self.round,
            self.owner,
            self.vault,
            myAddress(),
            // self.pointDistribution,
            self.ticketPrice,
            self.fee);
        let address = contractAddress(init);
        send(SendParameters{
            to: address,
            value: 0,
            mode: SendRemainingValue | SendIgnoreErrors,
            code: init.code,
            data: init.data,
            bounce: true,
            body: "identify".asComment()
        });
        self.roundControllerAddressMap.set(self.round, address);
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

    receive(msg: TonMillion_TonOne_EndRound) {
        self.requireOwner();
        let controller = self.roundControllerAddressMap.get(msg.round);
        require(controller != null, "RoundController is null");
        send(SendParameters {
            to: controller!!,
            // value: ton("0.05"),
            value: 0,
            mode: SendRemainingValue | SendIgnoreErrors,
            bounce: true,
            body: TonMillion_TonOne_RoundController_RoundEnd{flag: random(1, 3)}.toCell()
        });
    }

    get fun round(): Int {
        return self.round;
    }

    get fun roundContract(round: Int): Address? {
        return self.roundControllerAddressMap.get(round);
    }

    get fun allRoundContract(): map<Int, Address> {
        return self.roundControllerAddressMap;
    }

    get fun getOwner(): Address {
        return self.owner;
    }

    get fun pointContractAddress(): Address {
        return self.pointAddress;
    }

    get fun getTicketPrice(): Int {
        return self.ticketPrice;
    }

//    get fun getPointDistribution(): Int {
//        return self.pointDistribution;
//    }

    get fun getFee(): Int {
        return self.fee;
    }
}
