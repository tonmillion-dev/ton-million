import "@stdlib/deploy";

message Test_Event {
    sender: Address;
    data: Int;
}

contract Test_Contract with Deployable {
    receive() {
        let ctx = context();
        emit(Test_Event{
            sender: ctx.sender,
            data: 1,
        }.toCell());
    }
}
