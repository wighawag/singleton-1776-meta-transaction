pragma solidity 0.6.1;

contract EIP1776MetaTxReceiverBase {

    address private _metaTxProcessor;
    constructor(address metaTxProcessor) internal {
        _metaTxProcessor = metaTxProcessor;
    }

    ///@dev the from need to be equal to the first parameter of the function using that modifier
    function isValidSender(address from) internal view returns(bool) {
        return msg.sender == from || isMetaTx();
    }

    function isMetaTx() internal view returns(bool) {
        return msg.sender == _metaTxProcessor;
    }
}
