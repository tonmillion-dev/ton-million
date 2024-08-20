

message TonMillion_CoinFlip_Betting {
    value: Bool;
}

message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forward_payload: Slice as remaining; // Comment Text message when Transfer the jetton
}

contract TonMillion_CoinFlip_Controller with Deployable, Ownable {
    const MinTonForStorage: Int = ton("0.01");
    owner: Address;
    tokenContract: Address;
    tokenWallet: Address;

    init(
        tokenContract: Address,
        tokenWallet: Address
    ) {
        self.owner = sender();
        self.tokenContract = tokenContract;
        self.tokenWallet = tokenWallet;
    }

    receive(msg: TokenNotification) {

    }

    receive(msg: TonMillion_CoinFlip_Betting) {
        let result = random(0, 1);
        if (result == 0 && !msg.value) {
            // true
        } else if (result == 1 && msg.value) {
            // true
        } else {
            // false
        }
    }

    fun handleSuccess() {
        let ctx = context();
        let sender = ctx.sender;

    }

    fun handleFailed() {

    }
}
