pragma solidity 0.6.1;

contract ExampleReceiver  {
    address /* immutable */ _metaTxProcessor;
    constructor(address metaTxProcessor) public {
        _metaTxProcessor = metaTxProcessor;
    }

    event Test(address from, string name);
    function doSomething(address from, string calldata name) external {
        require(msg.sender == from || msg.sender == _metaTxProcessor, "not authorized");
        emit Test(from, name);
    }
}
