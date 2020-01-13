pragma solidity 0.6.1;

import "../Libraries/AddressUtils.sol";
import "../Interfaces/ERC721TokenReceiver.sol";
import "../Interfaces/ERC721.sol";
import "../Interfaces/ERC721Enumerable.sol";

import "../EIP1776MetaTxReceiverBase.sol";

contract Numbers is /*ERC721, ERC721Enumerable,*/ EIP1776MetaTxReceiverBase { // interface seems to require overrides :(

    //////////////////////////// ERC721 Events /////////////
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
    /////////////////////////////////////////////////////////


    using AddressUtils for address;

    bytes4 internal constant _ERC721_RECEIVED = 0x150b7a02;

    bytes4 internal constant ERC165ID = 0x01ffc9a7;

    mapping(uint256 => uint256) _ownerAndIndex; // max 2**96 items, store both owner and item index
    mapping(address => uint256[]) _itemsPerOwner;
    mapping (address => mapping(address => bool)) public _operatorsForAll;
    mapping (uint256 => address) public _operators;

    uint256 internal _nextId = 1;

    constructor(address metaTxProcessor) public EIP1776MetaTxReceiverBase(metaTxProcessor) {}

    function isValidApproveOperator(address from) internal returns (bool) {
        return isValidSender(from) || _operatorsForAll[from][msg.sender];
    }

    function mint(address to) external {
        // TODO only specified minter can do
        uint256 id = _nextId++;
        uint256 index = _itemsPerOwner[to].length;
        _itemsPerOwner[to].push(id);
        _ownerAndIndex[id] = uint256(to) + index * 2**160;
        emit Transfer(address(0), to, id);
    }

    function _transferFrom(address from, address to, uint256 id, bool safe, bytes memory data) internal {
        (address owner, uint256 index, bool operatorEnabled) = _ownerIndexAndOperatorEnabledOf(id);
        require(owner != address(0), "DOES_NOT_EXIST");
        require(owner == from, "NOT_OWNER");
        require(to != address(0), "ZERO_ADDRESS");
        bool isMeta = isMetaTx();
        if (msg.sender != from && !isMeta) {
            require(
                _operatorsForAll[from][msg.sender] ||
                (operatorEnabled && _operators[id] == msg.sender),
                "NOT_AUTHORIZED"
            );
        }

        uint256 lastItemId = _itemsPerOwner[from][_itemsPerOwner[from].length-1]; // TODO for silidity: should pop return the item ?
        _itemsPerOwner[from].pop();
        if (id != lastItemId) {
            _itemsPerOwner[from][index] = lastItemId;
            _ownerAndIndex[lastItemId] = uint256(from) + index * 2**160;
        }

        uint256 newIndex = _itemsPerOwner[to].length;
        _itemsPerOwner[to].push(id);
        _ownerAndIndex[id] = uint256(to) + newIndex * 2**160;
        emit Transfer(from, to, id);
        if (safe && to.isContract()) {
            require(
                _checkOnERC721Received(isMeta ? from : msg.sender, from, to, id, data),
                "ERC721_TRANSFER_FAILED"
            );
        }
    }

    /**
     * @notice Return the number of Land owned by an address
     * @param owner The address to look for
     * @return The number of Land token owned by the address
     */
    function balanceOf(address owner) external view returns (uint256) {
        require(owner != address(0), "owner is zero address");
        return _itemsPerOwner[owner].length;
    }


    function _ownerOf(uint256 id) internal view returns (address tokenOwner) {
        tokenOwner = address(_ownerAndIndex[id]);
        require(tokenOwner != address(0), "token does not exist");
    }

    function _ownerAndOperatorEnabledOf(uint256 id) internal view returns (address owner, bool operatorEnabled) {
        uint256 data = _ownerAndIndex[id];
        owner = address(data);
        operatorEnabled = (data / 2**255) == 1;
    }

    function _ownerIndexAndOperatorEnabledOf(uint256 id) internal view returns (address owner, uint256 index, bool operatorEnabled) {
        uint256 data = _ownerAndIndex[id];
        owner = address(data);
        index = (data & 0xEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) / 2**160;
        operatorEnabled = (data / 2**255) == 1;
    }

    /**
     * @notice Return the owner of a Land
     * @param id The id of the Land
     * @return owner The address of the owner
     */
    function ownerOf(uint256 id) external view returns (address owner) {
        owner = _ownerOf(id);
        require(owner != address(0), "token does not exist");
    }

    function _approveFor(address sender, address operator, uint256 id) internal {
        (address owner, uint256 index, bool operatorEnabled) = _ownerIndexAndOperatorEnabledOf(id);
        require(owner != address(0), "DOES_NOT_EXIST");
        require(owner == sender, "NOT_OWNER");
        if(operator == address(0)) {
            _ownerAndIndex[id] = uint256(owner) + index * 2**160; // no need to resset the operator, it will be overriden next time
        } else {
            _ownerAndIndex[id] = uint256(owner) + index * 2**160 + 2**255;
            _operators[id] = operator;
        }
        emit Approval(owner, operator, id);
    }

    /**
     * @notice Approve an operator to spend tokens on the sender behalf
     * @param sender The address giving the approval
     * @param operator The address receiving the approval
     * @param id The id of the token
     */
    function approveFor(
        address sender,
        address operator,
        uint256 id
    ) external {
        require(sender != address(0), "ZERO_ADDRESS");
        require(isValidApproveOperator(sender), "NOT_AUTHORIZED");
        _approveFor(sender, operator, id);
    }

    /**
     * @notice Approve an operator to spend tokens on the sender behalf
     * @param operator The address receiving the approval
     * @param id The id of the token
     */
    function approve(address operator, uint256 id) external {
        address owner = _ownerOf(id);
        // NO META TX here as the first parameter is not the originator but the operator that is meant to be approved
        require(
            owner == msg.sender || // TODO remove duplicatre check
            _operatorsForAll[owner][msg.sender],
            "NOT_AUTHORIZED"
        );
        _approveFor(owner, operator, id);
    }

    /**
     * @notice Get the approved operator for a specific token
     * @param id The id of the token
     * @return The address of the operator
     */
    function getApproved(uint256 id) external view returns (address) {
        (address owner, bool operatorEnabled) = _ownerAndOperatorEnabledOf(id);
        require(owner != address(0), "DOES_NOT_EXIST");
        if (operatorEnabled) {
            return _operators[id];
        } else {
            return address(0);
        }
    }

    /**
     * @notice Transfer a token between 2 addresses
     * @param from The sender of the token
     * @param to The recipient of the token
     * @param id The id of the token
    */
    function transferFrom(address from, address to, uint256 id) external {
        _transferFrom(from, to, id, false, "");
    }

    /**
     * @notice Transfer a token between 2 addresses letting the receiver knows of the transfer
     * @param from The sender of the token
     * @param to The recipient of the token
     * @param id The id of the token
     * @param data Additional data
     */
    function safeTransferFrom(address from, address to, uint256 id, bytes memory data) public {
        _transferFrom(from, to, id, true, data);
    }

    /**
     * @notice Transfer a token between 2 addresses letting the receiver knows of the transfer
     * @param from The send of the token
     * @param to The recipient of the token
     * @param id The id of the token
     */
    function safeTransferFrom(address from, address to, uint256 id) external {
        safeTransferFrom(from, to, id, "");
    }

    /**
     * @notice Check if the contract supports an interface
     * 0x01ffc9a7 is ERC-165
     * 0x80ac58cd is ERC-721
     * 0x780e9d63 is ERC-721 Enumerable Extension
     * @param id The id of the interface
     * @return True if the interface is supported
     */
    function supportsInterface(bytes4 id) external pure returns (bool) {
        return id == 0x01ffc9a7 || id == 0x80ac58cd || id == 0x780e9d63;
    }

    /**
     * @notice Set the approval for an operator to manage all the tokens of the sender
     * @param sender The address giving the approval
     * @param operator The address receiving the approval
     * @param approved The determination of the approval
     */
    function setApprovalForAllFor(
        address sender,
        address operator,
        bool approved
    ) external {
        require(sender != address(0), "ZERO_ADDRESS");
        require(
            isValidSender(sender),
            "NOT_AUTHORIZED"
        );

        _setApprovalForAll(sender, operator, approved);
    }

    /**
     * @notice Set the approval for an operator to manage all the tokens of the sender
     * @param operator The address receiving the approval
     * @param approved The determination of the approval
     */
    function setApprovalForAll(address operator, bool approved) external {

        // NOT META TX ...
        _setApprovalForAll(msg.sender, operator, approved);
    }


    function _setApprovalForAll(
        address sender,
        address operator,
        bool approved
    ) internal {
        _operatorsForAll[sender][operator] = approved;
        emit ApprovalForAll(sender, operator, approved);
    }

    /**
     * @notice Check if the sender approved the operator
     * @param owner The address of the owner
     * @param operator The address of the operator
     * @return isOperator The status of the approval
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool isOperator)
    {
        return _operatorsForAll[owner][operator];
    }

    function _checkOnERC721Received(address operator, address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        bytes4 retval = ERC721TokenReceiver(to).onERC721Received(operator, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

    /////////////// erc721 ENUMERABLE //////////////
    function totalSupply() external view returns (uint256) {
        return _nextId - 1;
    }
    function tokenByIndex(uint256 index) external view returns (uint256) {
        revert("NOT SUPPORTED");
    }
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256) {
        return _itemsPerOwner[owner][index];
    }
}
