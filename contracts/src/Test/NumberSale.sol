pragma solidity 0.6.1;

import "../EIP1776MetaTxReceiverBase.sol";
import "./Numbers.sol";
import "../Interfaces/ERC20.sol";

contract NumberSale is EIP1776MetaTxReceiverBase {

    Numbers internal /*immutable*/ _numbers;
    ERC20 internal /*immutable*/ _erc20Token;
    uint256 internal /*immutable*/ _price;
    constructor(Numbers numbers, ERC20 erc20Token, uint256 price, address metaTxProcessor) public EIP1776MetaTxReceiverBase(metaTxProcessor) {
        _numbers = numbers;
        _erc20Token = erc20Token;
        _price = price;
    }

    function purchase(address from, address to) external {

        // this check whether
        // 1) the first parameter is msg.sender, in which case the user is using a normal tx
        // 2) or the msg.sender is equal the MetatxProcessor (which ensure the first paramter is the address of the metatx signer)
        require(isValidSender(from), "NOT_AUTHORIZED");


        // Here we transfer from the sender
        // this works because the meta tx processor will be owing the ERC20 token temporarly
        // This allow the user to never need to approve ERC20 token before hand when using metatx
        require(_erc20Token.transferFrom(msg.sender, address(this), _price), "ERC20_TRANSFER_FAILED");

        // if all is good we mint
        _numbers.mint(to);
    }
}
